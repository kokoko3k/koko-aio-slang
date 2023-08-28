#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 2) out vec3 vHALO_GAMMA;


void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;
    vHALO_GAMMA = vec3(HALO_GAMMA);
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 2) in vec3 vHALO_GAMMA;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 4) uniform sampler2D in_glow_pass;

#include "includes/functions.include.slang" 

void main() {
    if (DO_HALO == 0.0 ) return;
    
    vec3 pixel_haloed = texture(in_glow_pass, vTexCoord).rgb;
    if (HALO_NO_PREGAIN == 1.0)  pixel_haloed/= IN_GLOW_POWER;
    pixel_haloed = pow(pixel_haloed, vHALO_GAMMA);
    
    FragColor = vec4(pixel_haloed.rgb, 1.0);

}
