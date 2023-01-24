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
layout(set = 0, binding = 3) uniform sampler2D FXAA_pass;
layout(set = 0, binding = 4) uniform sampler2D first_pass;
layout(set = 0, binding = 5) uniform sampler2D shift_and_bleed_pass;


#include "includes/functions.include.slang" 

void main() { 
 
   if (DO_IN_GLOW == 0.0) return;
   
   //Pass the right texture unchanged for tighter blurs:
   if (IN_GLOW_W >= GLOW_SHARP_MAX || IN_GLOW_H >= GLOW_SHARP_MAX) {
      if ( DO_SHIFT_RGB + DO_SAT_BLEED > 0.0) 
         FragColor = texture(shift_and_bleed_pass, vTexCoord);
      else if (DO_FXAA > 0.0)
         FragColor = texture(FXAA_pass, vTexCoord);
      else
         FragColor = texture(first_pass, vTexCoord);
      return;      
   }

   
   vec3 pixel_glowed;
   if ( DO_SHIFT_RGB + DO_SAT_BLEED > 0.0)
      pixel_glowed = blur9_x(shift_and_bleed_pass, vTexCoord, global.first_passSize.xy, IN_GLOW_W);

   else if (DO_FXAA > 0.0)
      pixel_glowed = blur9_x(FXAA_pass,            vTexCoord, global.first_passSize.xy, IN_GLOW_W);

   else
      pixel_glowed = blur9_x(first_pass,           vTexCoord, global.first_passSize.xy, IN_GLOW_W);

   pixel_glowed = pow(pixel_glowed, vec3(IN_GLOW_GAMMA));
   FragColor = vec4((pixel_glowed),1.0);
}

