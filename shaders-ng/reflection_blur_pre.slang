#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vCoordsAdapted;

#include "includes/functions.include.slang"


void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   vCoordsAdapted = vTexCoord;
   //override aspect?
   if (DO_GAME_GEOM_OVERRIDE > 0.5)
      vCoordsAdapted = content_geom_override(vCoordsAdapted, GAME_GEOM_ASPECT, get_in_aspect(), GAME_GEOM_VSHIFT, GAME_GEOM_HSHIFT, GAME_GEOM_ZOOM);

   vCoordsAdapted = zoomout_coords( vCoordsAdapted, BEZEL_RFL_ZOOM, 1.0);
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vCoordsAdapted;

layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 1) uniform sampler2D flick_and_noise_pass;
layout(set = 0, binding = 2) uniform sampler2D avglum_pass;

#include "includes/functions.include.slang"
#include "includes/blooms.include.slang"

float borders_gradient(vec2 co, float smoothness) {
   //Draws a square with smooth borders:
   float size = 1.0;
   vec4 rect = vec4(0.0+smoothness, 0.0+smoothness, size - smoothness, size - smoothness);
   vec2 hv = smoothstep(rect.xy - smoothness, rect.xy, co) * smoothstep(co - smoothness, co, rect.zw);
   return  hv.x * hv.y;
}

void main() {
   
   if (DO_BEZEL == 0.0) return;
   
   float skip_border = BEZEL_REFL_SKIP_SIZE;
   if (vTexCoord.x > skip_border && vTexCoord.x < 1.0 - skip_border &&
       vTexCoord.y > skip_border && vTexCoord.y < 1.0 - skip_border ) {
      return;
   }
   
   vec2 coords = vCoordsAdapted;

   if (DO_DYNZOOM == 1.0) 
      coords = zoom(coords, get_dyn_zoom(avglum_pass));
 
   //eventually return black pixel
   if (coords.y < 0.0 || coords.y > 1.0 || coords.x < 0.0 || coords.x > 1.0) {
      FragColor = vec4(0.0);
      return;
   }

   
  //Create a gradient near borders to modulate between blurrend and sharp refection.
      float smoothness = 0.15;
      vec2 coords_shade = zoom(vTexCoord,1.05);
      float shade_sharp_blur = borders_gradient(coords_shade, smoothness);
      //shade_sharp_blur = 1.05 - (shade_sharp_blur + BEZEL_RFL_BLR_SHD); //Modulates between sharp and blur via user parameter
   
      shade_sharp_blur =  shade_sharp_blur - (BEZEL_RFL_BLR_SHD - 0.2);
      
      shade_sharp_blur=clamp(shade_sharp_blur, 0.0,1.0);
      float blur_radius=  (shade_sharp_blur) * 2.0  ;
      float blur_quality = 1;
      


      vec3 pixel_out = bloom(flick_and_noise_pass, coords, global.FinalViewportSize, vec2(blur_radius), blur_quality, 0.0, 1.0) ;

      
      
   
      
   FragColor = vec4(pixel_out,shade_sharp_blur );
//FragColor = vec4(shade_sharp_blur );
   
}
 
 
  
