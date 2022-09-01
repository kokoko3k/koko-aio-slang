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

#include "functions.include""
void main() {
   vec2 coords = vTexCoord;
   if (DO_BLOOM == 1) {
      if (DO_CURVATURE == 1.0) { 
         if ((GEOM_WARP_X > 0.0) || (GEOM_WARP_Y > 0.0)) coords = Warp(vTexCoord,GEOM_WARP_X,GEOM_WARP_Y);
         //if ((GEOM_BORDER_WX > 0.0) && (GEOM_BORDER_WY > 0.0)) coords = Warp(vTexCoord,GEOM_BORDER_WX,GEOM_BORDER_WY);
      }
      FragColor = texture(Original, coords);
   } else {
      return;
   }
}
 
  
