#version 450

#include "config.inc"
#include "includes/functions.include.slang"

#define AA_MODE_FXAA                 // 110 fps  // on fastest preset (good for 2x upscale)
#define AA_MODE_SCALE2XPLUS          // 111.2 fps //good general purpose, very light, but blurs edges too much? or not?; unsharp mask does not help.
#define AA_MODE_2XSCALEHQ            // 109.5 //used to blur too much shades, tweaked better now. rounder look than ddtxbrlv1, but rounds almost any corner.
#define AA_MODE_DDTXBRLV1            // 108.4 // a bit blurry, parameters do help, yes, done.
#define AA_MODE_SUPER2XSAI           // 106.5 // less Dirty.
//#define AA_MODE_MMPX                 // 98 //preserves a lot of details, too heavy.


#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

layout(location = 5) out vec4 vpt1;
layout(location = 6) out vec4 vpt2;

layout(location = 7) out vec4 vhqt1;
layout(location = 8) out vec4 vhqt2;
layout(location = 9) out vec4 vhqt3;
layout(location = 10) out vec4 vhqt4;

layout(location = 11) out vec4 vxt1;

layout(location = 12) out float vDo_flickering;
layout(location = 13) out vec2  vFlickerCoords;
layout(location = 14) out float vDynamicSeed;

void main() {

   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   
   //Generate a seed that changes over time for temporal random noise
   vDynamicSeed = mod(params.FrameCount, 120.0001);
   
   //flickering helper
   vDo_flickering  = float ( scanline_have_to_flicker(is_interlaced()) || FLICKER_IN_MOTION == 1.0  ) ; 
   if (vDo_flickering == 1.0) {
      //Flicker one over 3 frames:
         float ModFlicker = params.FrameCount % 3;
      
      //Compute y flicker offset:
         float FlickerOffset = 0.0;
         float line_tick = is_interlaced() ? 1 : 2 ;
         if (ModFlicker == 1.0 )
            FlickerOffset = params.OriginalSize.w/line_tick;
         else if (ModFlicker == 2.0)
            FlickerOffset = -params.OriginalSize.w/line_tick;
      //Export flicker coords for Fragment shader here:
         vFlickerCoords =  vec2(TexCoord.x, TexCoord.y + FlickerOffset);
   }

      
   #ifdef AA_MODE_SCALE2XPLUS
      vec2 pd = params.SourceSize.zw;

      vpt1 = vTexCoord.xyxy + vec4( 0,   -pd.y, -pd.x, 0);   // B, D
      vpt2 = vTexCoord.xyxy + vec4( pd.x,  0,    0,   pd.y); // F, H	
   #endif
      
   #ifdef AA_MODE_2XSCALEHQ
      vec2 s = params.SourceSize.zw * 0.5;
      vec2 dg1 = vec2( s.x, s.y);
      vec2 dg2 = vec2(-s.x, s.y);
      vec2 dx = vec2(s.x, 0.0);
      vec2 dy = vec2(0.0, s.y);
      vhqt1 = vec4(vTexCoord - dg1, vTexCoord - dy);
      vhqt2 = vec4(vTexCoord - dg2, vTexCoord + dx);
      vhqt3 = vec4(vTexCoord + dg1, vTexCoord + dy);
      vhqt4 = vec4(vTexCoord + dg2, vTexCoord - dx);
   #endif
      
      
   #ifdef AA_MODE_DDTXBRLV1
      vec2 xd = params.SourceSize.zw;
      vxt1.xy = vec2( xd.x,  0); // F
      vxt1.zw = vec2(  0, xd.y); // H
   #endif
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;


layout(location = 5) in vec4 vpt1;
layout(location = 6) in vec4 vpt2;

layout(location = 7) in vec4 vhqt1;
layout(location = 8) in vec4 vhqt2;
layout(location = 9) in vec4 vhqt3;
layout(location = 10) in vec4 vhqt4;

layout(location = 11) in vec4 vxt1;

layout(location = 12) in float vDo_flickering;
layout(location = 13) in vec2  vFlickerCoords;
layout(location = 14) in float vDynamicSeed;

layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;
layout(set = 0, binding = 3) uniform sampler2D upscale_passFeedback;


vec4 texture_ovr_nearest( sampler2D tex, vec2 co) {
   //return texture(tex, co);
   return texture_NEAREST(tex, co, params.SourceSize);
}

vec4 texture_ovr_nearest_lod0( sampler2D tex, vec2 co) {
   //return texture(tex, co);
   return texture_NEAREST_lod(tex, co, params.SourceSize, 0.0);
}

#ifdef AA_MODE_DDTXBRLV1

   /*
   Hyllian's DDT-xBR-lv1 Shader
   
   Copyright (C) 2011-2022 Hyllian/Jararaca - sergiogdb@gmail.com

   Sharpness control - Copyright (c) 2022 Filippo Scognamiglio

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in
   all copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
   THE SOFTWARE.
   */
   
   
   //    // set to 1.0 to use dynamic sharpening
   //    #pragma parameter USE_DYNAMIC_SHARPNESS "Dynamic Sharpness [ 0FF | ON ]" 1.0 0.0 1.0 1.0
   // 
   //    // Set to 1.0 to bias the interpolation towards sharpening
   //    #pragma parameter USE_SHARPENING_BIAS "Sharpness Bias [ 0FF | ON ]" 1.0 0.0 1.0 1.0
   // 
   //    // Minimum amount of sharpening in range [0.0, 1.0]
   //    #pragma parameter DYNAMIC_SHARPNESS_MIN "Dynamic Sharpness Min" 0.0 0.0 1.0 0.1
   // 
   //    // Maximum amount of sharpening in range [0.0, 1.0]
   //    #pragma parameter DYNAMIC_SHARPNESS_MAX "Dynamic Sharpness Max" 0.3 0.0 1.0 0.1
   // 
   //    // If USE_DYNAMIC_SHARPNESS is 0 apply this static sharpness
   //    #pragma parameter STATIC_SHARPNESS "Static Sharpness" 0.5 0.0 1.0 0.1
   // 
   //    #pragma parameter DDT_THRESHOLD "DDT Diagonal Threshold" 2.6 1.0 6.0 0.2
   // 
   //    #define USE_DYNAMIC_SHARPNESS  params.USE_DYNAMIC_SHARPNESS
   //    #define USE_SHARPENING_BIAS    params.USE_SHARPENING_BIAS
   //    #define DYNAMIC_SHARPNESS_MIN  (params.DYNAMIC_SHARPNESS_MIN * 0.5)
   //    #define DYNAMIC_SHARPNESS_MAX  (params.DYNAMIC_SHARPNESS_MAX * 0.5)
   //    #define STATIC_SHARPNESS       (params.STATIC_SHARPNESS * 0.5)
   //    #define DDT_THRESHOLD params.DDT_THRESHOLD
   // 
   
   #define WP1  4.0
   #define WP2  1.0
   #define WP3 -1.0

   #define USE_DYNAMIC_SHARPNESS  1.0
      #define USE_SHARPENING_BIAS    1.0
      #define DYNAMIC_SHARPNESS_MIN  0.1  // default: (0.0 * 0.5)
      #define DYNAMIC_SHARPNESS_MAX  0.25 // default: (0.3 * 0.5)

   #define STATIC_SHARPNESS       (0.5 * 0.5)
   #define DDT_THRESHOLD 2.6
   
   const vec3 Y = vec3( 0.299,  0.587,  0.114);

   float luma(vec3 color) {
   return dot(color, Y);
   }

   float linearStep(float edge0, float edge1, float t) {
      return clamp((t - edge0) / (edge1 - edge0), 0.0, 1.0);
   }

   float sharpSmooth(float t, float sharpness) {
      return linearStep(sharpness, 1.0 - sharpness, t);
   }

   vec3 quadBilinear(vec3 a, vec3 b, vec3 c, vec3 d, vec2 p, float sharpness){
      float x = sharpSmooth(p.x, sharpness);
      float y = sharpSmooth(p.y, sharpness);
      return mix(mix(a, b, x), mix(c, d, x), y);
   }

   // Fast computation of barycentric coordinates only in the sub-triangle 1 2 4
   vec3 fastBarycentric(vec2 p, float sharpness) {
      float l0 = sharpSmooth(1.0 - p.x - p.y, sharpness);
      float l1 = sharpSmooth(p.x, sharpness);
      return vec3(l0, l1, 1.0 - l0 - l1);
   }

   vec3 triangleInterpolate(vec3 t1, vec3 t2, vec3 t3, vec3 t4, vec2 c, float sharpness) {
      // Alter colors and coordinates to compute the other triangle.
      bool altTriangle = 1.0 - c.x < c.y;
      vec3 cornerColor = altTriangle ? t3 : t1;
      //vec2 triangleCoords = altTriangle ? vec2(1.0 - c.y, 1.0 - c.x) : c;
      vec2 triangleCoords;
      if (altTriangle) {
         triangleCoords = vec2(1.0 - c.y, 1.0 - c.x);
      } else {
         triangleCoords = c;
      }
      vec3 weights = fastBarycentric(triangleCoords, sharpness);
      return weights.x * cornerColor + weights.y * t2 + weights.z * t4;
   } 
   
   vec3 aa_ddtxbrlv1(sampler2D tex, vec2 co, vec4 pt1) {
   
      vec2 pos = fract(co*params.SourceSize.xy)-vec2(0.5); // pos = pixel position
      vec2 dir = sign(pos); // dir = pixel direction
      float lmax, lmin, contrast;
      float sharpness = STATIC_SHARPNESS;

      vec2 g1 = dir*pt1.xy;
      vec2 g2 = dir*pt1.zw;

      vec3 A = texture_ovr_nearest_lod0(tex, vTexCoord       ).xyz;
      vec3 B = texture_ovr_nearest_lod0(tex, vTexCoord +g1   ).xyz;
      vec3 C = texture_ovr_nearest_lod0(tex, vTexCoord    +g2).xyz;
      vec3 D = texture_ovr_nearest_lod0(tex, vTexCoord +g1+g2).xyz;

      vec3 A1 = texture_ovr_nearest_lod0(tex, vTexCoord    -g2).xyz;
      vec3 B1 = texture_ovr_nearest_lod0(tex, vTexCoord +g1-g2).xyz;
      vec3 A0 = texture_ovr_nearest_lod0(tex, vTexCoord -g1   ).xyz;
      vec3 C0 = texture_ovr_nearest_lod0(tex, vTexCoord -g1+g2).xyz;

      vec3 B2 = texture_ovr_nearest_lod0(tex, vTexCoord +2*g1     ).xyz;
      vec3 D2 = texture_ovr_nearest_lod0(tex, vTexCoord +2*g1+  g2).xyz;
      vec3 C3 = texture_ovr_nearest_lod0(tex, vTexCoord      +2*g2).xyz;
      vec3 D3 = texture_ovr_nearest_lod0(tex, vTexCoord   +g1+2*g2).xyz;

      float a = luma(A);
      float b = luma(B);
      float c = luma(C);
      float d = luma(D);

      if (USE_DYNAMIC_SHARPNESS == 1.0) {
         lmax = max(max(a, b), max(c, d));
         lmin = min(min(a, b), min(c, d));
         contrast = (lmax - lmin) / (lmax + lmin + 0.05);

         if (USE_SHARPENING_BIAS == 1.0)
            contrast = sqrt(contrast);

         sharpness = mix(DYNAMIC_SHARPNESS_MIN, DYNAMIC_SHARPNESS_MAX, contrast);
      }	
      
      float a1 = luma(A1);
      float b1 = luma(B1);
      float a0 = luma(A0);
      float c0 = luma(C0);

      float b2 = luma(B2);
      float d2 = luma(D2);
      float c3 = luma(C3);
      float d3 = luma(D3);

      float p = abs(pos.x);
      float q = abs(pos.y);

      //    A1 B1
      // A0 A  B  B2
      // C0 C  D  D2
      //    C3 D3

      float wd1 = (WP1*abs(a-d) + WP2*(abs(b-a1) + abs(b-d2) + abs(c-a0) + abs(c-d3)) + WP3*(abs(a1-d2) + abs(a0-d3)));
      float wd2 = (WP1*abs(b-c) + WP2*(abs(a-b1) + abs(a-c0) + abs(d-b2) + abs(d-c3)) + WP3*(abs(b1-c0) + abs(b2-c3)));

      float irlv1 = (abs(a-b)+abs(a-c)+abs(d-c)+abs(d-b));

      vec3 color;

      if ( ((wd1+0.1*DDT_THRESHOLD)*DDT_THRESHOLD < wd2) && (irlv1 > 0.0) )
      {
            color = triangleInterpolate(B, D, C, A, vec2(q, 1-p), sharpness);
      }
      else if ( (wd1 > (wd2+0.1*DDT_THRESHOLD)*DDT_THRESHOLD) && (irlv1 > 0.0))
      {
            color = triangleInterpolate(A, B, D, C, vec2(p, q), sharpness);
      }
      else
         color = quadBilinear(A, B, C, D, vec2(p, q), sharpness);

      return color;
   }
   

#endif


#ifdef AA_MODE_MMPX
   // MMPX
   // by Morgan McGuire and Mara Gagiu
   // https://casual-effects.com/research/McGuire2021PixelArt/
   // License: MIT
   // adapted for slang by hunterk
   float mmpx_luma(vec3 col){
      return dot(col, vec3(0.2126, 0.7152, 0.0722));
   }

   // I tried using a hash to speed these up but it didn't really help
   bool same(vec3 B, vec3 A0){
      return all(equal(B, A0));
   }

   bool notsame(vec3 B, vec3 A0){
      return any(notEqual(B, A0));
   }

   bool all_eq2(vec3 B, vec3 A0, vec3 A1) {
      return (same(B,A0) && same(B,A1));
   }

   bool all_eq3(vec3 B, vec3 A0, vec3 A1, vec3 A2) {
      return (same(B,A0) && same(B,A1) && same(B,A2));
   }

   bool all_eq4(vec3 B, vec3 A0, vec3 A1, vec3 A2, vec3 A3) {
      return (same(B,A0) && same(B,A1) && same(B,A2) && same(B,A3));
   }

   bool any_eq3(vec3 B, vec3 A0, vec3 A1, vec3 A2) {
      return (same(B,A0) || same(B,A1) || same(B,A2));
   }

   bool none_eq2(vec3 B, vec3 A0, vec3 A1) {
      return (notsame(B,A0) && notsame(B,A1));
   }

   bool none_eq4(vec3 B, vec3 A0, vec3 A1, vec3 A2, vec3 A3) {
      return (notsame(B,A0) && notsame(B,A1) && notsame(B,A2) && notsame(B,A3));
   }
 
   vec3 tex_src(vec2 co, float ox, float oy) {
      return texture_ovr_nearest_lod0(Source, co + vec2(ox, oy) * params.SourceSize.zw).rgb;
   }
   
   vec3 aa_mmpx(sampler2D tex, vec2 co) {
      // these do nothing, but just for consistency with the original code...

      // Our current pixel
         vec3 E = tex_src(co, 0.0,0.0);

      // Input: A-I central 3x3 grid
         vec3 A = tex_src(co, -1.,-1.);
         vec3 B = tex_src(co, +0.,-1.);
         vec3 C = tex_src(co, +1.,-1.);

         vec3 D = tex_src(co, -1.,+0.);
         vec3 F = tex_src(co, +1.,+0.);

         vec3 G = tex_src(co, -1.,+1.);
         vec3 H = tex_src(co, +0.,+1.);
         vec3 I = tex_src(co, +1.,+1.);

      // Default to Nearest magnification
         vec3 J = E;
         vec3 K = E;
         vec3 L = E;
         vec3 M = E;
      // Go ahead and put this here so we can use an early return on the next
      // line to save some cycles
         vec3 pixel_out = E;
         
      // Skip constant 3x3 centers and just use nearest-neighbor
      // them.  This gives a good speedup on spritesheets with
      // lots of padding and full screen images with large
      // constant regions such as skies.
      // EDIT: this is a wash for me, but we'll keep it around
      if(same(E,A) && same(E,B) && same(E,C) && same(E,D) && same(E,F) && same(E,G) && same(E,H) && same(E,I)) 
         return pixel_out;

      // Read additional values at the tips of the diamond pattern
         vec3 P  = tex_src(co, +0.,-2.);
         vec3 Q  = tex_src(co, -2.,+0.);
         vec3 R  = tex_src(co, +2.,+0.);
         vec3 S  = tex_src(co, +0.,+2.);

      // Precompute luminances
         float Bl = mmpx_luma(B);
         float Dl = mmpx_luma(D);
         float El = mmpx_luma(E);
         float Fl = mmpx_luma(F);
         float Hl = mmpx_luma(H);

      // Round some corners and fill in 1:1 slopes, but preserve
      // sharp right angles.
      //
      // In each expression, the left clause is from
      // EPX and the others are new. EPX
      // recognizes 1:1 single-pixel lines because it
      // applies the rounding only to the LINE, and not
      // to the background (it looks at the mirrored
      // side).  It thus fails on thick 1:1 edges
      // because it rounds *both* sides and produces an
      // aliased edge shifted by 1 dst pixel.  (This
      // also yields the mushroom-shaped arrow heads,
      // where that 1-pixel offset runs up against the
      // 2-pixel aligned end; this is an inherent
      // problem with 2X in-palette scaling.)
      //
      // The 2nd clause clauses avoid *double* diagonal
      // filling on 1:1 slopes to prevent them becoming
      // aliased again. It does this by breaking
      // symmetry ties using luminance when working with
      // thick features (it allows thin and transparent
      // features to pass always).
      //
      // The 3rd clause seeks to preserve square corners
      // by considering the center value before
      // rounding.
      //
      // The 4th clause identifies 1-pixel bumps on
      // straight lines that are darker than their
      // background, such as the tail on a pixel art
      // "4", and prevents them from being rounded. This
      // corrects for asymmetry in this case that the
      // luminance tie breaker introduced.

      // .------------ 1st ------------.      .----- 2nd ---------.      .------ 3rd -----.      .--------------- 4th -----------------------.
         if (((same(D,B) && notsame(D,H) && notsame(D,F))) && ((El>=Dl) || same(E,A)) && any_eq3(E,A,C,G) && ((El<Dl) || notsame(A,D) || notsame(E,P) || notsame(E,Q))) J=D;
         if (((same(B,F) && notsame(B,D) && notsame(B,H))) && ((El>=Bl) || same(E,C)) && any_eq3(E,A,C,I) && ((El<Bl) || notsame(C,B) || notsame(E,P) || notsame(E,R))) K=B;
         if (((same(H,D) && notsame(H,F) && notsame(H,B))) && ((El>=Hl) || same(E,G)) && any_eq3(E,A,G,I) && ((El<Hl) || notsame(G,H) || notsame(E,S) || notsame(E,Q))) L=H;
         if (((same(F,H) && notsame(F,B) && notsame(F,D))) && ((El>=Fl) || same(E,I)) && any_eq3(E,C,G,I) && ((El<Fl) || notsame(I,H) || notsame(E,R) || notsame(E,S))) M=F;

      // Clean up disconnected line intersections.
      //
      // The first clause recognizes being on the inside
      // of a diagonal corner and ensures that the "foreground"
      // has been correctly identified to avoid
      // ambiguous cases such as this:
      //
      //  o#o#
      //  oo##
      //  o#o#
      //
      // where trying to fix the center intersection of
      // either the "o" or the "#" will leave the other
      // one disconnected. This occurs, for example,
      // when a pixel-art letter "B" or "R" is next to
      // another letter on the right.
      //
      // The second clause ensures that the pattern is
      // not a notch at the edge of a checkerboard
      // dithering pattern.
      // 
      // >
      //  .--------------------- 1st ------------------------.      .--------- 2nd -----------. 
         if ((notsame(E,F) && all_eq4(E,C,I,D,Q) && all_eq2(F,B,H)) && notsame(F,tex_src(co, +3.,0.0))) K=M=F;
         if ((notsame(E,D) && all_eq4(E,A,G,F,R) && all_eq2(D,B,H)) && notsame(D,tex_src(co, -3.,0.0))) J=L=D;
         if ((notsame(E,H) && all_eq4(E,G,I,B,P) && all_eq2(H,D,F)) && notsame(H,tex_src(co, 0.0,+3.))) L=M=H;
         if ((notsame(E,B) && all_eq4(E,A,C,H,S) && all_eq2(B,D,F)) && notsame(B,tex_src(co, 0.0,-3.))) J=K=B;

      // Remove tips of bright triangles on dark
      // backgrounds. The luminance tie breaker for 1:1
      // pixel lines leaves these as sticking up squared
      // off, which makes bright triangles and diamonds
      // look bad.
         if ((Bl<El) && all_eq4(E,G,H,I,S) && none_eq4(E,A,D,C,F)) J=K=B;
         if ((Hl<El) && all_eq4(E,A,B,C,P) && none_eq4(E,D,G,I,F)) L=M=H;
         if ((Fl<El) && all_eq4(E,A,D,G,Q) && none_eq4(E,B,C,I,H)) K=M=F;
         if ((Dl<El) && all_eq4(E,C,F,I,R) && none_eq4(E,B,A,G,H)) J=L=D;

      //////////////////////////////////////////////////////////////////////////////////
      // Do further neighborhood peeking to identify
      // 2:1 and 1:2 slopes of constant color.
      // The first clause of each rule identifies a 2:1 slope line
      // of consistent color.
      //
      // The second clause verifies that the line is separated from
      // every adjacent pixel on one side and not part of a more
      // complex pattern. Common subexpressions from the second clause
      // are lifted to an outer test on pairs of rules.
      // 
      // The actions taken by rules are unusual in that they extend
      // a color assigned by previous rules rather than drawing from
      // the original source image.
      //
      // The comments show a diagram of the local
      // neighborhood in which letters shown with the
      // same shape and color must match each other and
      // everything else without annotation must be
      // different from the solid colored, square
      // letters.
         if (notsame(H,B)) { // Common subexpression
                           // Above a 2:1 slope or -2:1 slope   ◢ ◣
                           // First:
            if (notsame(H,A) && notsame(H,E) && notsame(H,C)) {
                           // Second:
                           //     P 
                           //   Ⓐ B C .
                           // Q D 🄴 🅵 🆁
                           //   🅶 🅷 I
                           //     S
               if (all_eq3(H,G,F,R) && none_eq2(H,D,tex_src(co, +2.,-1.))) L=M;
                           // Third:
                           //     P 
                           // . A B Ⓒ
                           // 🆀 🅳 🄴 F R
                           //   G 🅷 🅸
                           //     S
               if (all_eq3(H,I,D,Q) && none_eq2(H,F,tex_src(co, -2.,-1.))) M=L;
            }
                              
                           // Below a 2:1 (◤) or -2:1 (◥) slope (reflect the above 2:1 patterns vertically)
            if (notsame(B,I) && notsame(B,G) && notsame(B,E)) {
                           //     P 
                           //   🅰 🅱 C
                           // Q D 🄴 🅵 🆁
                           //   Ⓖ H I .
                           //     S
               if (all_eq3(B,A,F,R) && none_eq2(B,D,tex_src(co, +2.,+1.))) J=K;
                           //     P 
                           //   A 🅱 🅲
                           // 🆀 🅳 🄴 F R
                           // . G H Ⓘ 
                           //     S
               if (all_eq3(B,C,D,Q) && none_eq2(B,F,tex_src(co, -2.,+1.))) K=J;
            }
         }

         if (notsame(F,D)) { // Common subexpression
                              
                           // Right of a -1:2 (\) or -1:2 (/) slope (reflect the left 1:2 patterns horizontally)
            if (notsame(D,I) && notsame(D,E) && notsame(D,C)) {
                           //     P
                           //   🅰 B Ⓒ
                           // Q 🅳 🄴 F R
                           //   G 🅷 I
                           //     🆂 .
               if (all_eq3(D,A,H,S) && none_eq2(D,B,tex_src(co, +1.,+2.))) J=L;
                           //     🅿 .
                           //   A 🅱 C
                           // Q 🅳 🄴 F R
                           //   🅶 H Ⓘ
                           //     S
               if (all_eq3(D,G,B,P) && none_eq2(D,H,tex_src(co, +1.,-2.))) L=J;
            }
                              
                           // Left of a 1:2 (/) slope or -1:2 (\) slope (transpose the above 2:1 patterns)
                           // Pull common none_eq subexpressions out

            if (notsame(F,E) && notsame(F,A) && notsame(F,G)) {
                           //     P     
                           //   Ⓐ B 🅲   
                           // Q D 🄴 🅵 R 
                           //   G 🅷 I   
                           //   . 🆂   
               if (all_eq3(F,C,H,S) && none_eq2(F,B,tex_src(co, -1.,+2.))) K=M;
                           //   . 🅿
                           //   A 🅱 C
                           // Q D 🄴 🅵 R
                           //   Ⓖ H 🅸
                           //     S
               if (all_eq3(F,I,B,P) && none_eq2(F,H,tex_src(co, -1.,-2.))) M=K;
            }
         }

      // Determine which of our 4 output pixels we need to use
         vec2 a = fract(co * params.SourceSize.xy);
         return (a.x < 0.5) ? (a.y < 0.5 ? J : L) : (a.y < 0.5 ? K : M);
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
   
   vec3 aa_super2x_sai(sampler2D tex,  vec2 co) {
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


#ifdef AA_MODE_SCALE2XPLUS

   vec3 aa_scale2xplus(sampler2D tex, vec2 co, vec4 pt1, vec4 pt2) {
      /*
         Scale2xPlus shader 
         - Copyright (C) 2007 guest(r) - guest.r@gmail.com
         - License: GNU-GPL  

         The Scale2x algorithm:
         - Scale2x Homepage: http://scale2x.sourceforge.net/
         - Copyright (C) 2001, 2002, 2003, 2004 Andrea Mazzoleni 
         - License: GNU-GPL  
      */

      vec2 fp = fract(co*params.SourceSize.xy);

      // Reading the texels
         vec3 B = texture_ovr_nearest_lod0(tex, pt1.xy).xyz;
         vec3 D = texture_ovr_nearest_lod0(tex, pt1.zw).xyz;
         vec3 E = texture_ovr_nearest_lod0(tex, co).xyz;
         vec3 F = texture_ovr_nearest_lod0(tex, pt2.xy).xyz;
         vec3 H = texture_ovr_nearest_lod0(tex, pt2.zw).xyz;

      vec3 E0 = D == B && B != H && D != F ? D : E;
      vec3 E1 = B == F && B != H && D != F ? F : E;
      vec3 E2 = D == H && B != H && D != F ? D : E;
      vec3 E3 = H == F && B != H && D != F ? F : E;

      // Product interpolation
      return (E3*fp.x+E2*(1-fp.x))*fp.y+(E1*fp.x+E0*(1-fp.x))*(1-fp.y);
   }
#endif


#ifdef AA_MODE_2XSCALEHQ
   vec3 aa_2xscalehq(sampler2D tex, vec2 co, vec4 pt1, vec4 pt2, vec4 pt3, vec4 pt4) {
      float mx = 0.325;      // start smoothing wt.
      float k = -0.250;      // wt. decrease factor //does not seem to affect anything
      float max_w = 0.25 * 0.0;    // max filter weigth // the lower, the less "debanding"
      float min_w =-0.05;    // min filter weigth
      float lum_add = 0.25;  // affects smoothing
      vec3 c00 = texture_ovr_nearest_lod0(tex, pt1.xy).xyz; 
      vec3 c10 = texture_ovr_nearest_lod0(tex, pt1.zw).xyz; 
      vec3 c20 = texture_ovr_nearest_lod0(tex, pt2.xy).xyz; 
      vec3 c01 = texture_ovr_nearest_lod0(tex, pt4.zw).xyz; 
      vec3 c11 = texture_ovr_nearest_lod0(tex, co).xyz; 
      vec3 c21 = texture_ovr_nearest_lod0(tex, pt2.zw).xyz; 
      vec3 c02 = texture_ovr_nearest_lod0(tex, pt4.xy).xyz; 
      vec3 c12 = texture_ovr_nearest_lod0(tex, pt3.zw).xyz; 
      vec3 c22 = texture_ovr_nearest_lod0(tex, pt3.xy).xyz; 

      float md1 = dot(abs(c00 - c22), vec3(1.0));
      float md2 = dot(abs(c02 - c20), vec3(1.0));

      float w1 = dot(abs(c22 - c11), vec3(1.0)) * md2;
      float w2 = dot(abs(c02 - c11), vec3(1.0)) * md1;
      float w3 = dot(abs(c00 - c11), vec3(1.0)) * md2;
      float w4 = dot(abs(c20 - c11), vec3(1.0)) * md1;

      float t1 = w1 + w3;
      float t2 = w2 + w4;
      float ww = max(t1, t2) + 0.0001;

      c11 = (w1 * c00 + w2 * c20 + w3 * c22 + w4 * c02 + ww * c11) / (t1 + t2 + ww);

      float lc1 = k / (0.12 * dot(c10 + c12 + c11, vec3(1.0)) + lum_add);
      float lc2 = k / (0.12 * dot(c01 + c21 + c11, vec3(1.0)) + lum_add);

      w1 = clamp(lc1 * dot(abs(c11 - c10), vec3(1.0)) + mx, min_w, max_w);
      w2 = clamp(lc2 * dot(abs(c11 - c21), vec3(1.0)) + mx, min_w, max_w);
      w3 = clamp(lc1 * dot(abs(c11 - c12), vec3(1.0)) + mx, min_w, max_w);
      w4 = clamp(lc2 * dot(abs(c11 - c01), vec3(1.0)) + mx, min_w, max_w);
      return (w1 * c10) + (w2 * c21) + (w3 * c12) + (w4 * c01) + (1.0 - w1 - w2 - w3 - w4) * c11;
   }
#endif


vec3 pixel_flickering(vec3 pixel_cur) {
/* Simulates the flickering effect of the interlaced screens.
 * As I remember, it was visible when a line and the next had high
 * luminosity differences.
 * So we need to sample the current line and the previous one
 * (eventually applying color corrections to both).
 *
 * Repeating the following:
 * On frame 0, return the "clean" pixel
 * On frame 1, mix the upper pixel with the current one
 * On frame 2, mix the lower pixel with the current one
 *
 * The effect of the mix is the flickering itself, and we modulate
 * the mix according to the luminance difference between the current
 * pixel and the mixed one.
 *
 * We choose to alternate on a period of 3,
 * (thus considering the upper pixel and the lower one)
 * or else the high pixel persistance of lcd displays wont allow
 * to see the effect (the lcd panel would just mix the pixels by itself (meh).
 */

   //vec3 pixel_cur = texture_NEAREST(Source,vTexCoord, params.OriginalSize).rgb;
   //vec3 pixel_cur = texture(Source,vTexCoord).rgb;      
   //vec3 flickline = texture_NEAREST(upscale_passFeedback,vFlickerCoords, params.OriginalSize).rgb;
   //vec3 flickline = texture(upscale_passFeedback,vFlickerCoords).rgb;
   vec3 flickline = texture(Source,vFlickerCoords).rgb;
   //vec3 flickline = texture_NEAREST(Source,vFlickerCoords, params.OriginalSize).rgb;
   
   //float lumdiff = abs( flickline.r + flickline.g + flickline.b - pixel_cur.r - pixel_cur.g - pixel_cur.b);
   //float lumdiff = abs( (flickline.r + flickline.g) + (flickline.b - pixel_cur.r) - (pixel_cur.g + pixel_cur.b) ); //1687 1754 2946   ASM PROOF: FASTER
   float lumdiff = abs( dot(flickline.rgb, vec3(1.0)) - dot(pixel_cur.rgb, vec3(1.0)));// 1685 1750 2948 //ASM PROOF: Faster on SIMD8 and SIMD16, slower on SIMD32

   lumdiff = min(lumdiff * PIXELGRID_INTR_FLICK_POWR, 1.0);
   
   /*if (FLICKER_IN_MOTION == 1.0) {
      lumdiff = 0.4;
      vec3 prev_frame = texture(colortools_and_ntsc_passFeedback, vTexCoord).rgb;
      vec3 cur_frame = texture(colortools_and_ntsc_pass, vTexCoord).rgb;
      float is_moving = float(prev_frame != cur_frame);
      lumdiff *= is_moving;
   }*/
   
   return mix(pixel_cur.rgb,flickline.rgb,lumdiff);
   //return vec4( mix(pixel_cur.rgb,flickline.rgb,lumdiff),
   //             pixel_cur.a); //<-- wee need to return the alpha channel because it carries ntsc artifact mask
}


#ifndef FXAA_PRESET
    #define FXAA_PRESET 0
#endif

#if (FXAA_PRESET == 0)  //Dumb preset, looks like others for 2x scaling, but skip search.
    #define FXAA_EDGE_THRESHOLD      (1.0/8.0)
    #define FXAA_EDGE_THRESHOLD_MIN  (1.0/24.0)
    #define FXAA_SEARCH_STEPS        0
    #define FXAA_SEARCH_THRESHOLD    (1.0/4.0)
    #define FXAA_SUBPIX_CAP          (3.0/4.0)
    #define FXAA_SUBPIX_TRIM         (1.0/8.0)
#endif

#if (FXAA_PRESET == 6)
    #define FXAA_EDGE_THRESHOLD      (1.0/16.0)
    #define FXAA_EDGE_THRESHOLD_MIN  (1.0/12.0)
    #define FXAA_SEARCH_STEPS        4
    #define FXAA_SEARCH_THRESHOLD    (1.0/4.0)
    #define FXAA_SUBPIX_CAP          (7.0/8.0)
    #define FXAA_SUBPIX_TRIM         (1.0/8.0)
#endif

#if (FXAA_PRESET == 3)
    #define FXAA_EDGE_THRESHOLD      (1.0/16.0)
    #define FXAA_EDGE_THRESHOLD_MIN  (1.0/16.0)
    #define FXAA_SEARCH_STEPS        16
    #define FXAA_SEARCH_THRESHOLD    (1.0/4.0)
    #define FXAA_SUBPIX_CAP          (3.0/4.0)
    #define FXAA_SUBPIX_TRIM         (1.0/4.0)
#endif
#if (FXAA_PRESET == 4)
    #define FXAA_EDGE_THRESHOLD      (1.0/8.0)
    #define FXAA_EDGE_THRESHOLD_MIN  (1.0/24.0)
    #define FXAA_SEARCH_STEPS        1
    #define FXAA_SEARCH_THRESHOLD    (1.0/4.0)
    #define FXAA_SUBPIX_CAP          (3.0/4.0)
    #define FXAA_SUBPIX_TRIM         (1.0/8.0)
#endif
#if (FXAA_PRESET == 5)
    #define FXAA_EDGE_THRESHOLD      (1.0/16.0)
    #define FXAA_EDGE_THRESHOLD_MIN  (1.0/12.0)
    #define FXAA_SEARCH_STEPS        32
    #define FXAA_SEARCH_THRESHOLD    (1.0/4.0)
    #define FXAA_SUBPIX_CAP          (7.0/8.0)
    #define FXAA_SUBPIX_TRIM         (1.0/8.0)
#endif

#define FXAA_SUBPIX_TRIM_SCALE (1.0/(1.0 - FXAA_SUBPIX_TRIM))

// Return the luma, the estimation of luminance from rgb inputs.
// This approximates luma using one FMA instruction,
// skipping normalization and tossing out blue.
// FxaaLuma() will range 0.0 to 2.963210702.
float FxaaLuma(vec3 rgb) {
    //return rgb.y * (0.587/0.299) + rgb.x;
    return fma( rgb.y, (0.587/0.299), rgb.x ); //ASM_PROOF: SAME
}

vec3 FxaaLerp3(vec3 a, vec3 b, float amountOfA) {
    return (vec3(-amountOfA) * b) + ((a * vec3(amountOfA)) + b);
}

vec4 FxaaTexOff(sampler2D tex, vec2 pos, ivec2 off, vec4 sourcesize, vec4 outputsize) {
   float x = pos.x + float(off.x) * sourcesize.z;
   float y = pos.y + float(off.y) * sourcesize.w;   
   
   vec2 fragmentShift = off * outputsize.zw;
   vec2 shiftedUV = pos + fragmentShift;
   vec2 nearestUV = floor(shiftedUV * sourcesize.xy) * sourcesize.zw + sourcesize.zw * 0.5;
   
   return textureLod(tex, nearestUV, 0.0);    
}

// pos is the output of FxaaVertexShader interpolated across screen.
// xy -> actual texture position {0.0 to 1.0}
// sourcesize.zw should be a uniform equal to  {1.0/frameWidth, 1.0/frameHeight}
vec3 FxaaPixelShader(vec2 pos, sampler2D tex, vec4 sourcesize, vec4 outputsize) {

   vec3 rgbN = FxaaTexOff(tex, pos.xy, ivec2( 0,-1), sourcesize, outputsize).xyz;
   vec3 rgbW = FxaaTexOff(tex, pos.xy, ivec2(-1, 0), sourcesize, outputsize).xyz;
   vec3 rgbM = FxaaTexOff(tex, pos.xy, ivec2( 0, 0), sourcesize, outputsize).xyz;
   vec3 rgbE = FxaaTexOff(tex, pos.xy, ivec2( 1, 0), sourcesize, outputsize).xyz;
   vec3 rgbS = FxaaTexOff(tex, pos.xy, ivec2( 0, 1), sourcesize, outputsize).xyz;

   float lumaN = FxaaLuma(rgbN);
   float lumaW = FxaaLuma(rgbW);
   float lumaM = FxaaLuma(rgbM);
   float lumaE = FxaaLuma(rgbE);
   float lumaS = FxaaLuma(rgbS);

   float rangeMin = min(lumaM, min(min(lumaN, lumaW), min(lumaS, lumaE)));
   float rangeMax = max(lumaM, max(max(lumaN, lumaW), max(lumaS, lumaE)));

   float range = rangeMax - rangeMin;
   if(range < max(FXAA_EDGE_THRESHOLD_MIN, rangeMax * FXAA_EDGE_THRESHOLD)) {
      return rgbM;
   }
      
   vec3 rgbL = rgbN + rgbW + rgbM + rgbE + rgbS; //ASM_PROOF: USELESS parenthesis

   float lumaL = (lumaN + lumaW + lumaE + lumaS) * 0.25;
   float rangeL = abs(lumaL - lumaM);

   float blendL = max(0.0, (rangeL / range) - FXAA_SUBPIX_TRIM) * FXAA_SUBPIX_TRIM_SCALE; 
   blendL = min(FXAA_SUBPIX_CAP, blendL);

   vec3 rgbNW = FxaaTexOff(tex, pos.xy, ivec2(-1,-1), sourcesize, outputsize).xyz;
   vec3 rgbNE = FxaaTexOff(tex, pos.xy, ivec2( 1,-1), sourcesize, outputsize).xyz;
   vec3 rgbSW = FxaaTexOff(tex, pos.xy, ivec2(-1, 1), sourcesize, outputsize).xyz;
   vec3 rgbSE = FxaaTexOff(tex, pos.xy, ivec2( 1, 1), sourcesize, outputsize).xyz;

   rgbL += (rgbNW + rgbNE + rgbSW + rgbSE);

   rgbL *= vec3(1.0/9.0);
      
   float lumaNW = FxaaLuma(rgbNW);
   float lumaNE = FxaaLuma(rgbNE);
   float lumaSW = FxaaLuma(rgbSW);
   float lumaSE = FxaaLuma(rgbSE);

   float edgeVert = 
      abs((0.25 * lumaNW) + (-0.5 * lumaN) + (0.25 * lumaNE)) +
      abs((0.50 * lumaW ) + (-1.0 * lumaM) + (0.50 * lumaE )) +
      abs((0.25 * lumaSW) + (-0.5 * lumaS) + (0.25 * lumaSE));
   float edgeHorz = 
      abs((0.25 * lumaNW) + (-0.5 * lumaW) + (0.25 * lumaSW)) +
      abs((0.50 * lumaN ) + (-1.0 * lumaM) + (0.50 * lumaS )) +
      abs((0.25 * lumaNE) + (-0.5 * lumaE) + (0.25 * lumaSE));
      
   bool horzSpan = edgeHorz >= edgeVert;
 
   vec2 texel_size_scaled = sourcesize.zw * 0.5; //<-- KOKO, hack.

   float lengthSign = horzSpan ? -texel_size_scaled.y : -texel_size_scaled.x;

   if (!horzSpan) {
      lumaN = lumaW;
      lumaS = lumaE;
   }

   float gradientN = abs(lumaN - lumaM);
   float gradientS = abs(lumaS - lumaM);
   lumaN = (lumaN + lumaM) * 0.5;
   lumaS = (lumaS + lumaM) * 0.5;

   if (gradientN < gradientS) {
      lumaN = lumaS;
      lumaN = lumaS;
      gradientN = gradientS;
      lengthSign *= -1.0;
   }

   vec2 posN;
   posN.x = pos.x + (horzSpan ? 0.0 : lengthSign * 0.5);
   posN.y = pos.y + (horzSpan ? lengthSign * 0.5 : 0.0);

   gradientN *= FXAA_SEARCH_THRESHOLD;
      
   vec2 posP = posN;
   vec2 offNP = horzSpan ? vec2(texel_size_scaled.x, 0.0) : vec2(0.0, texel_size_scaled.y); 
   float lumaEndN = lumaN;
   float lumaEndP = lumaN;
   bool doneN = false;
   bool doneP = false;

   posN += offNP * vec2(-1.0, -1.0);
   posP += offNP * vec2( 1.0,  1.0);

   for(int i = 0; i < FXAA_SEARCH_STEPS; i++) {
      vec2 posN_adjusted;
      vec2 posP_adjusted;
      
      if (horzSpan) {
         posN_adjusted.x = coords_NEAREST(posN, params.SourceSize).x;
         posN_adjusted.y = posN.y;
         
         posP_adjusted.x = coords_NEAREST(posP, params.SourceSize).x;
         posP_adjusted.y = posP.y;
         
      } else {
         
         posN_adjusted.x = posN.x;
         posN_adjusted.y = coords_NEAREST(posN, params.SourceSize).y;
         
         posP_adjusted.x = posP.x;
         posP_adjusted.y = coords_NEAREST(posP, params.SourceSize).y;
      }
      
      
      if(!doneN) {
         lumaEndN = FxaaLuma(textureLod(tex, posN_adjusted.xy,0.0).xyz);
      }
      if(!doneP) {
         lumaEndP = FxaaLuma(textureLod(tex, posP_adjusted.xy,0.0).xyz);
      }
            
      doneN = doneN || (abs(lumaEndN - lumaN) >= gradientN);
      doneP = doneP || (abs(lumaEndP - lumaN) >= gradientN);
      
      if (doneN && doneP) {
         break;
      }
      
      if (!doneN) {
         posN -= offNP;
      }
      if (!doneP) {
         posP += offNP;
      }
   }

   float dstN = horzSpan ? pos.x - posN.x : pos.y - posN.y;
   float dstP = horzSpan ? posP.x - pos.x : posP.y - pos.y;
   bool directionN = dstN < dstP;
   lumaEndN = directionN ? lumaEndN : lumaEndP;

   if ( ((lumaM - lumaN) < 0.0) == ((lumaEndN - lumaN) < 0.0) ) {
      lengthSign = 0.0;
   }

   float spanLength = (dstP + dstN);
   dstN = directionN ? dstN : dstP;
   float subPixelOffset = (0.5 + (dstN * (-1.0/spanLength))) * lengthSign;

   vec2 smpco;
      
   if (horzSpan) {
      smpco.x = pos.x + 0.0;
      smpco.y = coords_NEAREST( pos + subPixelOffset, params.SourceSize ).y;
   } else {
      smpco.x = coords_NEAREST( pos + subPixelOffset, params.SourceSize ).x;
      smpco.y = pos.y + 0.0;
   }

   vec3 rgbF = textureLod(tex, smpco, 0.0).rgb;
   return FxaaLerp3(rgbL, rgbF, blendL); 
}

void main() {
   
   vec4 pixel_out;
   pixel_out.rgb = texture_ovr_nearest(Source, vTexCoord).rgb;
   
   float anoise;
   
   // If we sample ntsc articacts from a mipmap, we can smooth them
   // which is good when slective blurring them.
   pixel_out.a = 0.0;
   if (DO_NTSC_ARTIFACTS > 0.5) {
      pixel_out.a = textureLod(Source, vTexCoord, 1.0).a;
   }

/*
   if (DO_FXAA == 1.0) {
      pixel_out.rgb = FxaaPixelShader(vTexCoord, Source, params.SourceSize, params.OutputSize);
	}
*/


   if (DO_FXAA == 1.0) {
      pixel_out.rgb = FxaaPixelShader(vTexCoord, Source, params.SourceSize, params.OutputSize);
   } else
   if (DO_FXAA == 2.0) {
      pixel_out.rgb = aa_ddtxbrlv1(Source, vTexCoord, vxt1);
   } else
   if (DO_FXAA == 3.0) {
      pixel_out.rgb =  aa_2xscalehq(Source, vTexCoord , vhqt1, vhqt2, vhqt3, vhqt4);
   } else
   if (DO_FXAA == 4.0) {
      pixel_out.rgb = aa_scale2xplus(Source, vTexCoord, vpt1, vpt2);
   } else
   if (DO_FXAA == 5.0) {
      pixel_out.rgb = aa_super2x_sai(Source, vTexCoord);
   }/*
   if (DO_FXAA == 6.0) {
      pixel_out.rgb = aa_mmpx(Source, vTexCoord);
   }*/



   if (DO_RF_NOISE > 0.0) {
      float anoise = random_fast(vTexCoord * vDynamicSeed);
      pixel_out.rgb += scale_to_range(anoise, -RF_NOISE_STRENGTH, RF_NOISE_STRENGTH);
   }
      
   if (vDo_flickering==1.0) 
      pixel_out.rgb = pixel_flickering(pixel_out.rgb).rgb;
      

   //pixel_out.rgb = pow(pixel_out.rgb, vec3(1/2.2));
   
   FragColor = pixel_out;
   
}
