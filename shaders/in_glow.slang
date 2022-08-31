#version 450
#include "config.inc"


#define eps 1e-8
#define pi 3.141592654


// Blur sizes must not depend on input resolution
#define scalemod_x (global.scanline_flickering_passSize.x/360.0)
#define scalemod_y (global.scanline_flickering_passSize.y/270.0)


#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;


#include "functions.include"
void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = get_scaled_coords(TexCoord);
   vOutputCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D FXAA_pass;
layout(set = 0, binding = 3) uniform sampler2D Original;

// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "pixel_glows.slang"    
    

#include "functions.include"

vec4 main_wrap(void) {
    //Halo
    if (DO_IN_GLOW == 1.0 ) {
    vec2 in_glow_coords = vTexCoord;
        if (DO_CURVATURE == 1.0) {
            if ((GEOM_WARP_X > 0.0) || (GEOM_WARP_Y > 0.0))
                in_glow_coords = Warp(vTexCoord,GEOM_WARP_X,GEOM_WARP_Y);
        }
        vec3 pixel_glowed = pixel_glow(FXAA_pass, in_glow_wh,in_glow_wh,in_glow_power,in_glow_gamma,in_glow_coords, global.FXAA_passSize, global.FXAA_passSize).rgb;
        return vec4(pixel_glowed.rgb,1.0);
    }
    //Out
    return vec4(vec3(0.0),1.0);
}



void main() {
/*    bool is_border = false;
    if (border_needed()) {
        bool b_is_rotated = is_rotated();
        bool is_outside_x = ((vTexCoord.x > 1.0 ) || (vTexCoord.x < 0.0 ) );
        bool is_outside_y = ((vTexCoord.y > 1.0 ) || (vTexCoord.y < 0.0 ) );
        is_border = (b_is_rotated && is_outside_y) || (!b_is_rotated && is_outside_x);
   }
   
   if (is_border)
       FragColor = mark_outer_frame(vec3(0.0));
   else
       FragColor = main_wrap();
*/
     FragColor = main_wrap();
}
