#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;


void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D FXAA_pass;
layout(set = 0, binding = 3) uniform sampler2D first_pass;
layout(set = 0, binding = 4) uniform sampler2D in_glow_pass;
layout(set = 0, binding = 5) uniform sampler2D shift_and_bleed_pass;

#include "includes/functions.include.slang" 

void main() {
    if (DO_HALO == 0.0 ) return;

    vec3 pixel_haloed;

    if (DO_IN_GLOW == 1.0)
        pixel_haloed = glow9_x(in_glow_pass, vTexCoord, global.FXAA_passSize.xy, HALO_W, 1.0);
    else if ( DO_SHIFT_RGB + DO_SAT_BLEED > 0.0)
        pixel_haloed = glow9_x(shift_and_bleed_pass, vTexCoord, global.FXAA_passSize.xy, HALO_W, 1.0);
    else if (DO_FXAA > 0.0)
        pixel_haloed = glow9_x(FXAA_pass, vTexCoord, global.FXAA_passSize.xy, HALO_W, 1.0);
    else
        pixel_haloed = glow9_x(first_pass, vTexCoord, global.FXAA_passSize.xy, HALO_W, 1.0);
        
    pixel_haloed = pow(pixel_haloed, vec3(HALO_GAMMA));
    FragColor = vec4(pixel_haloed.rgb,1.0);
}
