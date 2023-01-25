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
   vIN_GLOW_W = IN_GLOW_W / NEW_SCALEMOD_X; //Make it resolution independent.
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float vIN_GLOW_W;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 5) uniform sampler2D shift_and_bleed_pass;


#include "includes/functions.include.slang" 

void main() { 
   if (DO_IN_GLOW == 0.0) return;
   
   //Pass the right texture unchanged for tighter blurs:
   if (IN_GLOW_W >= GLOW_SHARP_MAX && IN_GLOW_H >= GLOW_SHARP_MAX) {
      FragColor = texture(shift_and_bleed_pass, vTexCoord);
      return;
   }
   
   vec3 pixel_glowed;
   FragColor = vec4( blur9_x(shift_and_bleed_pass, vTexCoord, global.first_passSize.xy, vIN_GLOW_W), 1.0);

}

