#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out float vIN_GLOW_W;

void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;  

   float IN_GLOW_W_ADAPTED = IN_GLOW_W;
   
   //Auto calc glow sharpness via IN_GLOW_SPREAD
   if (IN_GLOW_W <= 0.00001)
      IN_GLOW_W_ADAPTED= IN_GLOW_SPREAD * IN_GLOW_SHARPNESS_SPREAD_RATIO_W;

   //don't allow lower values that look bad:
   IN_GLOW_W_ADAPTED = max(IN_GLOW_W_ADAPTED, MIN_IN_GLOW_SHARP);

   vIN_GLOW_W = IN_GLOW_W_ADAPTED / NEW_SCALEMOD_X; //Make it resolution independent.
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float vIN_GLOW_W;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 5) uniform sampler2D shift_and_bleed_pass;


#include "includes/functions.include.slang" 

void main() { 
   if (DO_IN_GLOW == 0.0) return;
   
   //Don't do anything if IN_GLOW_W and IN_GLOW_H are over the upper limit
   if (IN_GLOW_W >= GLOW_SHARP_MAX && IN_GLOW_H >= GLOW_SHARP_MAX) {
      return;
   }
   
   vec3 pixel_glowed;

   //Here lies the blur modifier from ntsc pass to glow.
   //I'm not expecting any performance hit, 
   //since the lookup should have been cached already or will serve so.
      float blur_modifier = texture(shift_and_bleed_pass, vTexCoord).a;
      float vIN_GLOW_W_adapted = vIN_GLOW_W - (blur_modifier * IN_GLOW_NTSC_ARTF_MULT);
      vIN_GLOW_W_adapted = clamp(vIN_GLOW_W_adapted, MIN_IN_GLOW_SHARP, 7.0); // Obey minimum sharpness.

   FragColor = vec4( blur9_x(shift_and_bleed_pass, vTexCoord, global.first_passSize.xy, vIN_GLOW_W_adapted), 1.0);

}

