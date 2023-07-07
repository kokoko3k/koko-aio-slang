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
         //Delta render?
         if (DELTA_RENDER == 1.0) {
            float DR_unchanged = float( textureLod(shift_and_bleed_pass,         vTexCoord, DELTA_RENDER_CHECK_AREA).rgb == 
                                        textureLod(shift_and_bleed_passFeedback, vTexCoord, DELTA_RENDER_CHECK_AREA).rgb);
            FragColor = vec4(0.0,0.0,0.0,DR_unchanged); 
            return;
         }
      }

      
   float IN_GLOW_W_ADAPTED = IN_GLOW_W;
   //Auto calc glow sharpness via IN_GLOW_SPREAD
      if (IN_GLOW_W <= 0.00001)
         IN_GLOW_W_ADAPTED = IN_GLOW_SPREAD * IN_GLOW_SHARPNESS_SPREAD_RATIO_W;


   //Here lies the blur modifier from ntsc pass to glow.
   //I'm not expecting any performance hit, 
   //since the lookup should have been cached already or will serve so.
      float ntsc_artifacts = texture(shift_and_bleed_pass, vTexCoord).a;

   
   //finally "add" them to the configured sharpness (-> less blur)
      IN_GLOW_W_ADAPTED = IN_GLOW_W_ADAPTED + ((1-ntsc_artifacts) * NTSC_ARTF_NOBLUR);

   //don't allow lower values that look bad:
      IN_GLOW_W_ADAPTED = max(IN_GLOW_W_ADAPTED, MIN_IN_GLOW_SHARP);

   //Make it resolution independent.
      IN_GLOW_W_ADAPTED = IN_GLOW_W_ADAPTED / NEW_SCALEMOD_X;

   //Delta render?
      float DR_unchanged = 0.0;
      if (DELTA_RENDER == 1.0) {
         //Keep track of changed pixels to speedup rendering in final pass   
         DR_unchanged = float( textureLod(shift_and_bleed_pass,         vTexCoord, DELTA_RENDER_CHECK_AREA).rgb == 
                                     textureLod(shift_and_bleed_passFeedback, vTexCoord, DELTA_RENDER_CHECK_AREA).rgb);
      }
      
   FragColor = vec4( blur9_x(shift_and_bleed_pass, vTexCoord, global.flick_and_noise_passSize.xy, IN_GLOW_W_ADAPTED), DR_unchanged);

   //To debug ntsc artifacts mask:
   if (NTSC_SHOW_ARTF_MASK > 0.5)
      FragColor = vec4(ntsc_artifacts);
   
}

