#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Original;
layout(set = 0, binding = 3) uniform sampler2D in_glow_and_scanline_flickering_pass;
layout(set = 0, binding = 4) uniform sampler2D FXAA_pass;

#include "functions.include""
void main() {
   vec2 coords = vTexCoord;
   if (DO_BLOOM == 1) {
      if (DO_CURVATURE == 1.0) { 
         if ((GEOM_WARP_X > 0.0) || (GEOM_WARP_Y > 0.0))
            coords = Warp(vTexCoord,GEOM_WARP_X,GEOM_WARP_Y);
         //if ((GEOM_BORDER_WX > 0.0) && (GEOM_BORDER_WY > 0.0)) coords = Warp(vTexCoord,GEOM_BORDER_WX,GEOM_BORDER_WY);
      }
      //Get the first available pixel_in:
         bool flickering_scanlines = (DO_SCANLINES == 1.0) && scanline_have_to_flicker(is_interlaced()) ;
         if  ((DO_IN_GLOW == 1.0) || flickering_scanlines) {
            FragColor = texture(in_glow_and_scanline_flickering_pass,coords);
            return;
         } else if (DO_FXAA == 1.0) {
            FragColor = texture(FXAA_pass,coords) ;
            return;
         } else {
            FragColor = texture(Original,coords);
            return;
         }
   } else {
      //No bloom requested
      return;
   }
}
 
  
