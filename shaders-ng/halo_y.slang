#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out float vHALO_H;


void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   vHALO_H = HALO_H / NEW_SCALEMOD_Y; //Make it resolution independent.
   
   
       //vHALO_H = pow(vHALO_H, 2.0);
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float vHALO_H;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#include "includes/functions.include.slang"    


void main() {
    if (DO_HALO == 0.0 ) return;
   
    vec3 pixel_haloed;
    
   //apply just gamma and power for tighter blurs and exit:
   if (HALO_H >= GLOW_SHARP_MAX) {
      FragColor = vec4( glow_dumb(Source, HALO_POWER, 1.0, vTexCoord), 1.0);
      return;
   }
   
   pixel_haloed = blur9_y_gamma(Source, vTexCoord, params.SourceSize.xy, vHALO_H, vec3(HALO_GAMMA)) * HALO_POWER;
   //pixel_haloed = blur9_y      (Source, vTexCoord, params.SourceSize.xy, vHALO_H) * HALO_POWER;
   //pixel_haloed = pow(pixel_haloed, vec3(HALO_GAMMA));
   FragColor = vec4(pixel_haloed.rgb,1.0);
    
    
}
