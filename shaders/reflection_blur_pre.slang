#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec2 vTexCoord;

#include "includes/functions.include.slang"

void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;

layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 1) uniform sampler2D first_pass;
layout(set = 0, binding = 2) uniform sampler2D avglum_pass;

#include "includes/functions.include.slang"

void main() {
   
   if (DO_BEZEL == 0.0) return;

   
   float skip_border = BEZEL_REFL_SKIP_SIZE;
   if (vTexCoord.x > skip_border && vTexCoord.x < 1.0 - skip_border &&
       vTexCoord.y > skip_border && vTexCoord.y < 1.0 - skip_border ) {
      FragColor = vec4(0.0);
      return;
   }
   
   vec2 coords = vTexCoord;
   
   //override aspect
   if (DO_GAME_GEOM_OVERRIDE > 0.5) {
      coords = content_aspect_override(coords, GAME_GEOM_ASPECT, get_in_aspect());
      coords.y -= (GAME_GEOM_VSHIFT/10.0) *  (1 - BEZEL_INNER_ZOOM);
      coords.x -= (GAME_GEOM_HSHIFT/10.0) *  (1 - BEZEL_INNER_ZOOM);
      coords = zoom(coords, GAME_GEOM_ZOOM);
   }
   
   
   coords = zoomout_coords( coords, BEZEL_RFL_ZOOM, 1.0);
   
   if (DO_DYNZOOM == 1.0) 
      coords = zoom(coords, get_dyn_zoom(avglum_pass));
 
   //eventually return black pixel
   if (coords.y < 0.0 || coords.y > 1.0 || coords.x < 0.0 || coords.x > 1.0) {
      FragColor = vec4(0.0);
      return;
   }

   
   FragColor = texture(first_pass, coords);
}
 
 
  
