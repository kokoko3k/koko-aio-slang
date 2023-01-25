#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out float vHALO_W;


void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
    vHALO_W = HALO_W / NEW_SCALEMOD_X; //Make it resolution independent.

}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float vHALO_W;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 4) uniform sampler2D in_glow_pass;
layout(set = 0, binding = 5) uniform sampler2D shift_and_bleed_pass;

#include "includes/functions.include.slang" 

void main() {
    if (DO_HALO == 0.0 ) return;

   //Pass the right texture unchanged for tighter blurs:
   if (HALO_W >= GLOW_SHARP_MAX && HALO_H >= GLOW_SHARP_MAX) {
        if (DO_IN_GLOW == 1.0)
                FragColor = texture(in_glow_pass, vTexCoord);
            else
                FragColor = texture(shift_and_bleed_pass, vTexCoord);

      return;
   }
    
    vec3 pixel_haloed;
    if (DO_IN_GLOW == 1.0) {
        pixel_haloed = blur9_x(in_glow_pass, vTexCoord, global.FXAA_passSize.xy, vHALO_W);
    }
    else {
        pixel_haloed = blur9_x(shift_and_bleed_pass, vTexCoord, global.FXAA_passSize.xy, vHALO_W);
    }
    
    FragColor = vec4(pixel_haloed.rgb, 1.0);
}
