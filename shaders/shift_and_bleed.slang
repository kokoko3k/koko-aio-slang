#version 450
#include "config.inc"

#define RGB_SHIFT_RANGE 20

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 r_offset;
layout(location = 2) out vec2 g_offset;
layout(location = 3) out vec2 b_offset;

#include "includes/functions.include.slang"

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;  
   if (DO_SHIFT_RGB == 1.0) {
      r_offset=offsets_from_float(SHIFT_R+210.0,RGB_SHIFT_RANGE);
      g_offset=offsets_from_float(SHIFT_G+210.0,RGB_SHIFT_RANGE);
      b_offset=offsets_from_float(SHIFT_B+210.0,RGB_SHIFT_RANGE);
   }
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 r_offset;
layout(location = 2) in vec2 g_offset;
layout(location = 3) in vec2 b_offset;

layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 3) uniform sampler2D FXAA_pass;
layout(set = 0, binding = 4) uniform sampler2D first_pass;


vec3 rgb2hsv(vec3 c){
   vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
   vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
   vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

   float d = q.x - min(q.w, q.y);
   float e = 1.0e-10;
   return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}


vec3 pixel_offset(vec3 pixel_cur,vec2 coord, sampler2D in_texture, vec4 sourcesize2) {
      vec2 d = -vec2(sourcesize2.z, sourcesize2.w)*0.5;
      vec3 pixel_offset;
      pixel_offset.r=texture(in_texture,coord + r_offset * d).r;
      pixel_offset.g=texture(in_texture,coord + g_offset * d).g;
      pixel_offset.b=texture(in_texture,coord + b_offset * d).b;
      return mix(pixel_cur,pixel_offset,OFFSET_STRENGTH);
}


vec3 pixel_offset_wrap (vec2 coord) {
   vec3 pixel_in;
   if ( DO_FXAA == 1.0)  {
      pixel_in = texture(FXAA_pass, vTexCoord).rgb;
      return pixel_offset(pixel_in, vTexCoord, FXAA_pass, global.FXAA_passSize);
   } else {
      pixel_in = texture(first_pass, vTexCoord).rgb;
      return pixel_offset(pixel_in, vTexCoord, first_pass, global.first_passSize);
   }
}

#define off1 1.0
#define w1 0.125
#define off2 2.0
#define w2  0.125
#define off3 3.0
#define w1 0.125
#define off4 4.0
#define w2  0.125

vec3 pixel_bleed(vec3 pixel_out, vec2 co, sampler2D in_texture, vec4 sourcesize2) {
   
   float taps=20;
   vec3 smp;
   float p_sat;
   float w = SAT_BLEED_STRENGTH;
   for ( float i=1.0 ; i <=SAT_BLEED_SIZE ; i++ ){
      w = w/SAT_BLEED_FALLOFF;
      smp = texture(first_pass, co - vec2(sourcesize2.z*i,0.0)).rgb;
      p_sat = rgb2hsv(smp).y;
      p_sat *= w;
      pixel_out = mix(pixel_out,smp,p_sat);
      
   }
   return pixel_out;
   
   vec3 previous_pixel1 = texture(first_pass, co - vec2(sourcesize2.z*off1,0.0)).rgb;
   float previous_sat1 = rgb2hsv(previous_pixel1).y;
   vec3 previous_pixel2 = texture(first_pass, co - vec2(sourcesize2.z*off2,0.0)).rgb;
   float previous_sat2 = rgb2hsv(previous_pixel2).y;

   /*vec3 next_pixel1 = texture(first_pass, co + vec2(sourcesize2.z*off1,0.0)).rgb;
   float next_sat1 = rgb2hsv(next_pixel1).y;
   vec3 next_pixel2 = texture(first_pass, co + vec2(sourcesize2.z*off2,0.0)).rgb;
   float next_sat2 = rgb2hsv(next_pixel2).y;
   */
   previous_sat1*=w1;
   previous_sat2*=w2;

   /*next_sat1*=w1;
   next_sat2*=w2;
   */

   pixel_out = mix(pixel_out,previous_pixel1,previous_sat1);
   pixel_out = mix(pixel_out,previous_pixel2,previous_sat2);

   /*result_pixel = mix(result_pixel,next_pixel2,next_sat2);
   result_pixel = mix(result_pixel,next_pixel2,next_sat2);*/
   return pixel_out;
}




void main() {
   if (DO_SHIFT_RGB + DO_SAT_BLEED == 0.0) return;
   
   //Handle case where both are needed:
   //First shift the right source, then pass it to bleed function.
   if (DO_SHIFT_RGB + DO_SAT_BLEED > 1.0) {
      vec3 pixel_out = pixel_offset_wrap(vTexCoord);
      if (DO_SAT_BLEED > 0.0) {      
         if ( DO_FXAA == 1.0)  {
            pixel_out = pixel_bleed(pixel_out, vTexCoord, FXAA_pass, global.FXAA_passSize);
         } else {
            pixel_out = pixel_bleed(pixel_out, vTexCoord, first_pass, global.first_passSize);
         }
      }
      FragColor = vec4(pixel_out,0.0);
      return;
   }
   
   //Handle case where only color shifting is requested
   if (DO_SHIFT_RGB > 0.0) {
      vec3 pixel_out = pixel_offset_wrap(vTexCoord);
      FragColor = vec4(pixel_out,0.0);
      return;
   }
   
   //Handle case where only chroma bleed is requested
   if (DO_SAT_BLEED > 0.0) {      
      vec3 pixel_out;
      if ( DO_FXAA == 1.0)  {
         pixel_out = texture(FXAA_pass, vTexCoord).rgb;
         pixel_out = pixel_bleed(pixel_out, vTexCoord, FXAA_pass, global.FXAA_passSize);
      } else {
         pixel_out = texture(first_pass, vTexCoord).rgb;
         pixel_out = pixel_bleed(pixel_out, vTexCoord, first_pass, global.first_passSize);
      }
      FragColor = vec4(pixel_out,0.0);
      return;
   }
   

}

