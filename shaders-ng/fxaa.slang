#version 450

#include "config.inc"

//#define AA_MODE_GUEST_ADVANCEDAA
#define AA_MODE_SUPER2XSAI

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec4 t1;
layout(location = 2) out vec4 t2;
layout(location = 3) out vec4 t3;
layout(location = 4) out vec4 t4;


void main() {
		
	gl_Position = global.MVP * Position;
	vTexCoord = TexCoord;
    
   #ifdef AA_MODE_GUEST_ADVANCEDAA
      vec2 d = params.SourceSize.zw * 0.5;
      t1.xy = vTexCoord + vec2(-d.x, 0);
      t2.xy = vTexCoord + vec2( d.x, 0);
      t3.xy = vTexCoord + vec2( 0,-d.y);
      t4.xy = vTexCoord + vec2( 0, d.y);
      t1.zw = vTexCoord + vec2(-d.x,-d.y);
      t2.zw = vTexCoord + vec2(-d.x, d.y);
      t3.zw = vTexCoord + vec2( d.x,-d.y);
      t4.zw = vTexCoord + vec2( d.x, d.y);
   #endif
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec4 t1;
layout(location = 2) in vec4 t2;
layout(location = 3) in vec4 t3;
layout(location = 4) in vec4 t4;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#include "includes/functions.include.slang"



vec4 texture_ovr( sampler2D tex, vec2 co) {
   //return texture(tex, co);
   return texture_NEAREST(tex, co, params.SourceSize);
}

#ifdef AA_MODE_GUEST_ADVANCEDAA
   vec3 AdvancedAA(sampler2D tex, vec2 co, vec4 pt1, vec4 pt2, vec4 pt3, vec4 pt4){
      /*
         Copyright (C) 2006 guest(r) - guest.r@gmail.com

         This program is free software; you can redistribute it and/or
         modify it under the terms of the GNU General Public License
         as published by the Free Software Foundation; either version 2
         of the License, or (at your option) any later version.

         This program is distributed in the hope that it will be useful,
         but WITHOUT ANY WARRANTY; without even the implied warranty of
         MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
         GNU General Public License for more details.

         You should have received a copy of the GNU General Public License
         along with this program; if not, write to the Free Software
         Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
      */

      /*
         The AdvancedAA shader is well used to:
         - AA 2xscaled gfx. to its 4x absolute size,   
         - AA hi-res "screens" (640x480) to their 2x size or,
         - AA gfx. back to it's original size (looks nice above 640x480, set scaling to 1.0) 
      */

      vec3 c00 = texture_ovr(tex, pt1.zw).xyz; 
      vec3 c10 = texture_ovr(tex, pt3.xy).xyz;
      vec3 c20 = texture_ovr(tex, pt3.zw).xyz;
      vec3 c01 = texture_ovr(tex, pt1.xy).xyz;
      vec3 c11 = texture_ovr(tex, co).xyz;
      vec3 c21 = texture_ovr(tex, pt2.xy).xyz;
      vec3 c02 = texture_ovr(tex, pt2.zw).xyz;
      vec3 c12 = texture_ovr(tex, pt4.xy).xyz;
      vec3 c22 = texture_ovr(tex, pt4.zw).xyz;

      float d1=dot(abs(c00-c22),vec3(1))+0.0001;
      float d2=dot(abs(c20-c02),vec3(1))+0.0001;
      float hl=dot(abs(c01-c21),vec3(1))+0.0001;
      float vl=dot(abs(c10-c12),vec3(1))+0.0001;

      float k1=0.5*(hl+vl);
      float k2=0.5*(d1+d2);

      vec3 t1_vec3= ( hl*(c10+c12) + vl*(c01+c21) + k1*c11 ) /( 2.5*(hl+vl) );
      vec3 t2_vec3= ( d1*(c20+c02) + d2*(c00+c22) + k2*c11 ) /( 2.5*(d1+d2) );

      k1=dot(abs(t1_vec3-c11),vec3(1))+0.0001;
      k2=dot(abs(t1_vec3-c11),vec3(1))+0.0001;

      return ( (k1*t1_vec3) + (k2*t1_vec3) ) / (k1+k2);
      
   }
#endif

#ifdef AA_MODE_SUPER2XSAI

    /*              Super2xSaI code               */
    /*  Copied from the Dosbox source code        */
    /*  Copyright (C) 2002-2007  The DOSBox Team  */
    /*  License: GNU-GPL                          */
    /*  Adapted by guest(r) on 16.4.2007          */

   const vec3 dt = vec3(65536.0,256.0,1.0);
   float GET_RESULT(float A, float B, float C, float D) {
      return (sign(abs(A-C)+abs(A-D)) - sign(abs(B-C)+abs(B-D))); 
   }

   float reduce(vec3 color)    { 
      return dot(color,dt);
   }
   
   vec3 super2x_sai(sampler2D tex,  vec2 co) {
      vec2 OGL2Size    = params.SourceSize.xy;
      vec2 OGL2InvSize = params.SourceSize.zw;

      // Calculating texel coordinates

      vec2 OGL2Pos = co * OGL2Size.xy;
      vec2 fp  = fract(OGL2Pos);
      vec2 dx  = vec2(OGL2InvSize.x,0.0);
      vec2 dy  = vec2(0.0,OGL2InvSize.y);
      vec2 g1  = vec2( OGL2InvSize.x,OGL2InvSize.y);
      vec2 g2  = vec2(-OGL2InvSize.x,OGL2InvSize.y);

      vec2 pC4 = floor(OGL2Pos)/OGL2Size.xy + 0.5*OGL2InvSize;
      vec2 pC8 = pC4 + g1;

      // Reading the texels
         vec3 C0 = texture(tex,pC4-g1).xyz; 
         vec3 C1 = texture(tex,pC4-dy).xyz;
         vec3 C2 = texture(tex,pC4-g2).xyz;
         vec3 D3 = texture(tex,pC4-g2+dx).xyz;
         vec3 C3 = texture(tex,pC4-dx).xyz;
         vec3 C4 = texture(tex,pC4).xyz;
         vec3 C5 = texture(tex,pC4+dx).xyz;
         vec3 D4 = texture(tex,pC8-g2).xyz;
         vec3 C6 = texture(tex,pC4+g2).xyz;
         vec3 C7 = texture(tex,pC4+dy).xyz;
         vec3 C8 = texture(tex,pC8).xyz;
         vec3 D5 = texture(tex,pC8+dx).xyz;
         vec3 D0 = texture(tex,pC4+g2+dy).xyz;
         vec3 D1 = texture(tex,pC8+g2).xyz;
         vec3 D2 = texture(tex,pC8+dy).xyz;
         vec3 D6 = texture(tex,pC8+g1).xyz;

      vec3 p00,p10,p01,p11;

      float c0 = reduce(C0);float c1 = reduce(C1);
      float c2 = reduce(C2);float c3 = reduce(C3);
      float c4 = reduce(C4);float c5 = reduce(C5);
      float c6 = reduce(C6);float c7 = reduce(C7);
      float c8 = reduce(C8);float d0 = reduce(D0);
      float d1 = reduce(D1);float d2 = reduce(D2);
      float d3 = reduce(D3);float d4 = reduce(D4);
      float d5 = reduce(D5);float d6 = reduce(D6);

      
      if (c7 == c5 && c4 != c8) {
            p11 = p01 = C7;
      } else if (c4 == c8 && c7 != c5) {
            p11 = p01 = C4;
      } else if (c4 == c8 && c7 == c5) {
            float r;
            r = GET_RESULT(c5,c4,c6,d1);
            r+= GET_RESULT(c5,c4,c3,c1);
            r+= GET_RESULT(c5,c4,d2,d5);
            r+= GET_RESULT(c5,c4,c2,d4);

            if (r > 0.0)
                     p11 = p01 = C5;
            else if (r < 0.0)
                     p11 = p01 = C4;
            else {
                     p11 = p01 = 0.5*(C4+C5);
            }
      } else {
            if (c5 == c8 && c8 == d1 && c7 != d2 && c8 != d0)
                     p11 = 0.25*(3.0*C8+C7);
            else if (c4 == c7 && c7 == d2 && d1 != c8 && c7 != d6)
                     p11 = 0.25*(3.0*C7+C8);
            else
                     p11 = 0.5*(C7+C8);

            if (c5 == c8 && c5 == c1 && c4 != c2 && c5 != c0)
                     p01 = 0.25*(3.0*C5+C4);
            else if (c4 == c7 && c4 == c2 && c1 != c5 && c4 != d3)
                     p01 = 0.25*(3.0*C4+C5);
            else
                     p01 = 0.5*(C4+C5);
      }

      if (c4 == c8 && c7 != c5 && c3 == c4 && c4 != d2)
            p10 = 0.5*(C7+C4);
      else if (c4 == c6 && c5 == c4 && c3 != c7 && c4 != d0)
            p10 = 0.5*(C7+C4);
      else
            p10 = C7;

      if (c7 == c5 && c4 != c8 && c6 == c7 && c7 != c2)
            p00 = 0.5*(C7+C4);
      else if (c3 == c7 && c8 == c7 && c6 != c4 && c7 != c0)
            p00 = 0.5*(C7+C4);
      else
            p00 = C4;

      // Distributing the final products    

      vec3 color = 0.0.xxx;

      if (fp.x < 0.50)
      { if (fp.y < 0.50) color = p00; else color = p10;}
      else
      { if (fp.y < 0.50) color = p01; else color = p11;}
      
      return color;
      
      
   }
   
   
#endif




void main() {
	
   vec4 pixel_out;
   pixel_out.a = texture(Source, vTexCoord).a;
   
	if (DO_FXAA == 0.0) {
		pixel_out.rgb = texture_ovr(Source, vTexCoord).rgb;
		FragColor = pixel_out;
	}

   #ifdef AA_MODE_GUEST_ADVANCEDAA
      pixel_out.rgb = AdvancedAA(Source, vTexCoord, t1, t2, t3, t4);
   #endif
      
   #ifdef AA_MODE_SUPER2XSAI
      pixel_out.rgb = super2x_sai(Source, vTexCoord);
   #endif
      
   FragColor = pixel_out;
   
}