#version 450
#include "config.inc"

#define RGB_SHIFT_RANGE 20

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vR_offset;
layout(location = 2) out vec2 vG_offset;
layout(location = 3) out vec2 vB_offset;
layout(location = 4) out float vDo_shadow_mode;

#include "includes/functions.include.slang"

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;  
   
   //...to tell fragment shader if dot matrix feature requests shadows.
      vDo_shadow_mode = float(DOT_M_SHADOW_STR + DO_DOT_MATRIX > 1 + eps);
   
   //Shadow mode disables deconvergence, they do not coexist in real life.
   if (vDo_shadow_mode == 1.0) {
      vR_offset = vec2(DOT_M_SHADOW_OFF, abs(DOT_M_SHADOW_OFF));
      vG_offset = vR_offset;
      vB_offset = vR_offset;
   } else if (DO_SHIFT_RGB == 1.0) {
      vR_offset=offsets_from_float(SHIFT_R+210.0,RGB_SHIFT_RANGE);
      vG_offset=offsets_from_float(SHIFT_G+210.0,RGB_SHIFT_RANGE);
      vB_offset=offsets_from_float(SHIFT_B+210.0,RGB_SHIFT_RANGE);
   }
}


#pragma stage fragment
#include "includes/functions.include.slang"
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vR_offset;
layout(location = 2) in vec2 vG_offset;
layout(location = 3) in vec2 vB_offset;
layout(location = 4) in float vDo_shadow_mode;

layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 3) uniform sampler2D FXAA_pass;
layout(set = 0, binding = 4) uniform sampler2D flick_and_noise_pass;
layout(set = 0, binding = 5) uniform sampler2D colortools_and_ntsc_pass;

#define bandwidth_mhz_Y_ntsc 4.2
#define bandwidth_mhz_I 1.5
#define bandwidth_mhz_Q 0.5

const mat3 mat3_RGB2YIQ = mat3(
   0.2989,  0.5959,  0.2115,
   0.5870, -0.2744, -0.5229,
   0.1140, -0.3216,  0.3114);

const mat3 mat3_YIQ2RGB = mat3(
   1.0,     1.0,     1.0,
   0.956,  -0.2720, -1.1060,
   0.6210, -0.6474,  1.7046);

//https://www.sciencedirect.com/topics/computer-science/color-subcarrier
#define bandwidth_mhz_Y_pal 5.0
#define bandwidth_mhz_U 1.3
#define bandwidth_mhz_V 1.3

const mat3 mat3_RGB2YUV = mat3(
   0.299,     0.587,     0.114,
   -0.14713, -0.28886,   0.436,
   0.615,    -0.514991, -0.10001);

const mat3 mat3_YUV2RGB = mat3(
   1.000, 0.000,   1.13983,
   1.000,-0.39465,-0.58060,
   1.000, 2.03211, 0.00000);



vec3 deconvergence_shadow(vec3 pixel_cur,vec2 coord, sampler2D in_texture, vec4 sourcesize2) {
      //Emulates deconvergence or shadowing for dot matrix screens like Gameboy.
      //Since both effects should not coexist in real life, we use a singe function for both.
      //The function stays more or less the same, but rgb offsets calculated in vertex shader
      //will be the same for shadow mode. Hopefully shader texture cache will take care of
      //multiple sampling for the same tex coords.
   
      vec2 d = -vec2(sourcesize2.z, sourcesize2.w)*0.5;
      vec3 pixel_offset;
      
      pixel_offset.r=texture(in_texture,coord + vR_offset * d).r;
      pixel_offset.g=texture(in_texture,coord + vG_offset * d).g;
      pixel_offset.b=texture(in_texture,coord + vB_offset * d).b;
      
      vec3 deconvergence_mode = mix(pixel_cur, pixel_offset, OFFSET_STRENGTH);
      vec3 shadow_mode = pixel_cur - max( (pixel_cur - pixel_offset), vec3(0.0) ) * DOT_M_SHADOW_STR;
      
      return mix_step(deconvergence_mode, shadow_mode, vDo_shadow_mode);
      
      
      //Shadow mode:
      //return  pixel_cur - 
      //       max( (pixel_cur - pixel_offset), vec3(0.0) ) * OFFSET_STRENGTH;
}


vec3 deconvergence_shadow_wrap (vec2 coord) {
   if ( DO_FXAA == 1.0)  {
      return deconvergence_shadow(texture(FXAA_pass, vTexCoord).rgb,  vTexCoord, FXAA_pass, global.FXAA_passSize);
   } else {
      return deconvergence_shadow(texture(flick_and_noise_pass, vTexCoord).rgb, vTexCoord, flick_and_noise_pass, global.flick_and_noise_passSize);
   }
}


vec3 pixel_bleed_side_NTSC(vec3 pixel_in, vec2 co, float size, float side, sampler2D in_texture, vec4 sourcesize2) {
   //apply strength modifier to blur ntsc artifacts more.
   
   float strength_modifier = mix(1.0, texture(colortools_and_ntsc_pass,co).a, DO_NTSC_ARTIFACTS); 
   if (NTSC_SHOW_ARTF_MASK + DO_NTSC_ARTIFACTS == 2.0) return vec3(strength_modifier);
   float w = SAT_BLEED_STRENGTH * clamp (strength_modifier, (1-NTSC_ARTF_NOBLEED), 1.0 ); 
   vec3 blur_YIQ = pixel_in * mat3_RGB2YIQ;    //Work in YIQ space
   float i = 0.0;
   for ( i=1 ; i <= size ; i++ ){
       w=w/SAT_BLEED_FALLOFF;
      //w = w * exp(i*i*(1-SAT_BLEED_FALLOFF)*0.1);
      //w=clamp(w,0.0,1.0);
      vec3 smp_YIQ = texture(flick_and_noise_pass, co - side * vec2(sourcesize2.z*i,0.0)).rgb * mat3_RGB2YIQ;
      blur_YIQ.x = mix(blur_YIQ.x, smp_YIQ.x, w/bandwidth_mhz_Y_ntsc);   // Blur Y
      blur_YIQ.y = mix(blur_YIQ.y, smp_YIQ.y, w/bandwidth_mhz_I     );   // Blur I
      blur_YIQ.z = mix(blur_YIQ.z, smp_YIQ.z, w/bandwidth_mhz_Q     );   //  BlurQ
      //Tried to optimize as follows to no avail:
      //vec3 vec3_mix = vec3(w/bandwidth_mhz_Y_ntsc, w/bandwidth_mhz_I, w/bandwidth_mhz_Q);
      //blur_YIQ = mix(blur_YIQ.xyz, smp_YIQ.xyz, vec3_mix);
   }
   //blur_YIQ.z/=i;
   return blur_YIQ.xyz * mat3_YIQ2RGB; //return to RGB colorspace
}

vec3 pixel_bleed_side_PAL(vec3 pixel_in, vec2 co, float size, float side, sampler2D in_texture, vec4 sourcesize2) {
   float w = SAT_BLEED_STRENGTH;
   vec3 blur_YUV = pixel_in * mat3_RGB2YUV;    //Work in YIQ space
   float i = 0.0;
   for ( i=1 ; i <= size ; i++ ){
      w=w/SAT_BLEED_FALLOFF;
      //w=clamp(w,0.0,1.0);
      vec3 smp_YUV = texture(flick_and_noise_pass, co - side * vec2(sourcesize2.z*i,0.0)).rgb * mat3_RGB2YUV;
      blur_YUV.x = mix(blur_YUV.x, smp_YUV.x, w/bandwidth_mhz_Y_pal);    // Blur Y
      blur_YUV.y = mix(blur_YUV.y, smp_YUV.y, w/bandwidth_mhz_U     );   // Blur U
      blur_YUV.z = mix(blur_YUV.z, smp_YUV.z, w/bandwidth_mhz_V     );   // Blur V
   }
   return blur_YUV.xyz * mat3_YUV2RGB; //return to RGB colorspace
}

#define SIDE_RIGHT 1
#define SIDE_LEFT -1


vec3 pixel_bleed(vec3 pixel_in, vec2 co, sampler2D in_texture, vec4 sourcesize2) {
   vec3 side_left ; vec3 side_right;
   //Tried to unbranch the following, no gain (even worse) probably due to not using constants anymore.
   //Just dont try again.
   if (SAT_BLEED_PAL == 1.0) {
      side_right = pixel_bleed_side_PAL(pixel_in, co, SAT_BLEED_SIZE_RIGHT, SIDE_RIGHT, in_texture, sourcesize2);
      side_left = pixel_bleed_side_PAL(pixel_in, co, SAT_BLEED_SIZE_LEFT, SIDE_LEFT, in_texture, sourcesize2);
   } else {
      side_right = pixel_bleed_side_NTSC(pixel_in, co, SAT_BLEED_SIZE_RIGHT, SIDE_RIGHT, in_texture, sourcesize2);
      side_left = pixel_bleed_side_NTSC(pixel_in, co, SAT_BLEED_SIZE_LEFT, SIDE_LEFT, in_texture, sourcesize2);
   }
   //Clamping min to 0.0 is needed for nvidia to avoid bad graphical glitches, why? 
   return max( mix(side_left,side_right,0.5), 0.0) ;  

}
void main() {
   float pixel_alpha_ntsc_artifacts; // <- this holds ntsc artifacts needed by glow to modulate blur there.
   vec3 pixel_out;
   //Handle case where both are needed:
   //First shift the right source, then pass it to bleed function.
   if (DO_SHIFT_RGB + DO_SAT_BLEED > 1.0 || DOT_M_SHADOW_STR > 0.0 )  {
      pixel_out = deconvergence_shadow_wrap(vTexCoord);
      if (DO_SAT_BLEED > 0.0) {      
         if ( DO_FXAA == 1.0)  {
            pixel_out = pixel_bleed(pixel_out, vTexCoord, FXAA_pass, global.FXAA_passSize);
            pixel_alpha_ntsc_artifacts = texture(FXAA_pass, vTexCoord).a;
         } else {
            pixel_out = pixel_bleed(pixel_out, vTexCoord, flick_and_noise_pass, global.flick_and_noise_passSize);
            pixel_alpha_ntsc_artifacts = texture(flick_and_noise_pass, vTexCoord).a;
         }
      }
   } else
      //Handle case where only color shifting is requested
      if (DO_SHIFT_RGB > 0.0 || DOT_M_SHADOW_STR > 0.0) {
         pixel_out = deconvergence_shadow_wrap(vTexCoord);
         pixel_alpha_ntsc_artifacts = texture(flick_and_noise_pass, vTexCoord).a;
   } else 
      if (DO_SAT_BLEED > 0.0) {      
         //Handle case where only chroma bleed is requested
         if ( DO_FXAA == 1.0)  {
            pixel_out = texture(FXAA_pass, vTexCoord).rgb;
            pixel_alpha_ntsc_artifacts = texture(FXAA_pass, vTexCoord).a;
            pixel_out = pixel_bleed(pixel_out, vTexCoord, FXAA_pass, global.FXAA_passSize);
            
         } else {
            pixel_out = texture(flick_and_noise_pass, vTexCoord).rgb;
            pixel_alpha_ntsc_artifacts = texture(flick_and_noise_pass, vTexCoord).a;
            pixel_out = pixel_bleed(pixel_out, vTexCoord, flick_and_noise_pass, global.flick_and_noise_passSize);
         }
   } else
      //Passthrough
      if ( DO_FXAA == 1.0)  {
         pixel_out = texture(FXAA_pass, vTexCoord).rgb;
         pixel_alpha_ntsc_artifacts = texture(FXAA_pass, vTexCoord).a;
      } else {
         pixel_out = texture(flick_and_noise_pass, vTexCoord).rgb;
         pixel_alpha_ntsc_artifacts = texture(flick_and_noise_pass, vTexCoord).a;
      }

   //pre-gamma if needed by glow.
   if (DO_CCORRECTION > 0.5) 
      pixel_out = pow(pixel_out, vec3(IN_GLOW_GAMMA));
 
   FragColor = vec4(pixel_out,pixel_alpha_ntsc_artifacts);

}
