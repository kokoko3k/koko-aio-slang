#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;  
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 5) uniform sampler2D shift_and_bleed_pass;

layout(set = 0, binding = 6) uniform sampler2D shift_and_bleed_passFeedback;


#include "includes/functions.include.slang" 


#define PI 3.14159265359
float sinc(float x) {
    if (abs(x) < 0.001)
        return 1.0;

    x *= pi;
    return sin(x) / x;
}

vec3 lanczos(sampler2D sampler_in, vec2 co, vec4 texsize, float sharpness ) {
   
   float data_pix_no = co.x * texsize.x;
   float data_one    = texsize.z;
   
   float texel      = floor(data_pix_no);
   float phase      = data_pix_no - texel;
   float base_phase = phase - 0.5;
   vec2 tex         = vec2((texel + 0.5) * texsize.z, co.y);

   vec3 col = vec3(0.0);
   for (int i = -2; i <= 2; i++) {
      float phase = base_phase - float(i);
      phase*= sharpness;
      if (abs(phase) < 2.0) { //FIXME check needed?
         float g = sinc(phase);
         col += texture(sampler_in, tex + vec2(float(i) * data_one, 0.0)).rgb * g;
      }
   }

   return col * sharpness;
} 

vec3 blur_gauss_lanczos_wrap(sampler2D texture_in, vec2 co, vec4 sourcesize, float sharpness, bool use_gauss) {
   if (use_gauss)
      return blur9_x(texture_in, co, sourcesize.xy, sharpness);
         else
      return lanczos(texture_in, co, sourcesize, sharpness);
}


void main() { 
   if (DO_IN_GLOW == 0.0) {
      //Delta render?
      if (DELTA_RENDER == 1.0) {
         float DR_unchanged = float( textureLod(shift_and_bleed_pass,         vTexCoord, DELTA_RENDER_CHECK_AREA).rgb == 
                                     textureLod(shift_and_bleed_passFeedback, vTexCoord, DELTA_RENDER_CHECK_AREA).rgb);
         FragColor = vec4(0.0,0.0,0.0,DR_unchanged); 
         return;
      }
   };

   //Don't do anything if IN_GLOW_W and IN_GLOW_H are over the upper limit
      if (IN_GLOW_W >= GLOW_SHARP_MAX && IN_GLOW_H >= GLOW_SHARP_MAX) {
         vec4 passthrough = texture(shift_and_bleed_pass, vTexCoord);
         //Delta render?
         if (DELTA_RENDER == 1.0) {
            float DR_unchanged = float( textureLod(shift_and_bleed_pass,         vTexCoord, DELTA_RENDER_CHECK_AREA).rgb == 
                                        textureLod(shift_and_bleed_passFeedback, vTexCoord, DELTA_RENDER_CHECK_AREA).rgb);
            FragColor = vec4(passthrough.rgb, DR_unchanged);
            return;
         }
         FragColor = passthrough;
         return;
      }
      
   
   float IN_GLOW_W_ADAPTED = abs(IN_GLOW_W);
   
   //GLow to blur via IN_GLOW_SPREAD:
      //Spread amount needs to lessen its influence when going from glow to blur
         float in_glow_spread = IN_GLOW_SPREAD * (1-IN_GLOW_BIAS);
      //half in glow spread for lanczos
         if (IN_GLOW_W < 0.0) 
            in_glow_spread = in_glow_spread/2.0;
      //Modulate sharpness via IN_GLOW_SPREAD when IN_GLOW_W is under minimum blur sharpness
         if (IN_GLOW_W_ADAPTED < MIN_IN_GLOW_SHARP )
            IN_GLOW_W_ADAPTED = in_glow_spread * IN_GLOW_SHARPNESS_SPREAD_RATIO_W;
   
   //Modulate glow power via ntsc artifact mask:
      float ntsc_artifacts = texture(shift_and_bleed_pass, vTexCoord).a;
      
      //To debug ntsc artifacts mask:
         if (DO_NTSC_ARTIFACTS + NTSC_SHOW_ARTF_MASK > 1.5) {
            FragColor = vec4(ntsc_artifacts);
            return;
         }
      //finally "add" them to the configured sharpness (-> less blur)
         IN_GLOW_W_ADAPTED = IN_GLOW_W_ADAPTED +  DO_NTSC_ARTIFACTS * ((1-ntsc_artifacts) * NTSC_ARTF_NOBLUR);

   //don't allow lower values that look bad:
      IN_GLOW_W_ADAPTED = max(IN_GLOW_W_ADAPTED, MIN_IN_GLOW_SHARP);

   //Scale it for lanczos
      if (IN_GLOW_W < 0.0) 
         IN_GLOW_W_ADAPTED =  (IN_GLOW_W_ADAPTED+1)/10.0;
      
   //Make it resolution independent.
      IN_GLOW_W_ADAPTED = IN_GLOW_W_ADAPTED / NEW_SCALEMOD_X;
      

      
   //Delta render?
      float DR_unchanged = 0.0;
      if (DELTA_RENDER == 1.0) {
         //Keep track of changed pixels to speedup rendering in final pass   
         DR_unchanged = float( textureLod(shift_and_bleed_pass,         vTexCoord, DELTA_RENDER_CHECK_AREA).rgb == 
                               textureLod(shift_and_bleed_passFeedback, vTexCoord, DELTA_RENDER_CHECK_AREA).rgb);
      }
      

      
   //Finally blur horizontally 
   if ( abs(IN_GLOW_W) < GLOW_SHARP_MAX) {
         FragColor = vec4( blur_gauss_lanczos_wrap(shift_and_bleed_pass, vTexCoord, global.flick_and_noise_passSize, IN_GLOW_W_ADAPTED, (IN_GLOW_W >= 0.0) ), 
                           DR_unchanged);
   }else{
      FragColor = texture(shift_and_bleed_pass, vTexCoord, DR_unchanged);
   }
   
}

