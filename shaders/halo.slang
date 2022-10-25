#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 inglow_wh_vec2;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;
   // Blur radius must not depend on input resolution
   inglow_wh_vec2 = vec2(IN_GLOW_WH * (320.0/params.OutputSize.x), IN_GLOW_WH * (224.0/params.OutputSize.x));
   inglow_wh_vec2 = vec2(0.0,0.0);
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 inglow_wh_vec2;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D FXAA_pass;
layout(set = 0, binding = 3) uniform sampler2D first_pass;
layout(set = 0, binding = 4) uniform sampler2D in_glow_pass;

// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "includes/pixel_glows.include.slang"    


vec4 main_wrap(void) {
    //Halo
    vec3 pixel_haloed;
    vec2 halo_coords = vTexCoord;

    if (DO_IN_GLOW == 1.0)
        pixel_haloed = pixel_glow(in_glow_pass, HALO_W,HALO_H,HALO_POWER,HALO_GAMMA,halo_coords, params.OutputSize, params.OutputSize).rgb;
    else if (DO_FXAA == 1.0)
        pixel_haloed = pixel_glow(FXAA_pass, HALO_W,HALO_H,HALO_POWER,HALO_GAMMA,halo_coords, params.OutputSize, params.OutputSize).rgb;
    else
        pixel_haloed = pixel_glow(first_pass, HALO_W,HALO_H,HALO_POWER,HALO_GAMMA,halo_coords, params.OutputSize, params.OutputSize).rgb;
        
    return vec4(pixel_haloed.rgb,1.0);
}



void main() {
    if (DO_HALO == 1.0 ) {
        FragColor = main_wrap();
    } else {
        return;
    }
}
