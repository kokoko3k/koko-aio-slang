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

float borders_gradient(vec2 co, float smoothness) {
   //Draws a square with smooth borders:
   float size = 1.0;
   vec4 rect = vec4(0.0+smoothness, 0.0+smoothness, size - smoothness, size - smoothness);
   vec2 hv = smoothstep(rect.xy - smoothness, rect.xy, co) * smoothstep(co - smoothness, co, rect.zw);
   return  hv.x * hv.y;
}

void main() {
   if (DO_BEZEL == 0.0) return;
   
   vec2 coords = vTexCoord;
   
   //override aspect
   if (DO_GAME_GEOM_OVERRIDE > 0.5) {
      coords = content_aspect_override(coords, GAME_GEOM_ASPECT, get_in_aspect());
      coords.y += (GAME_GEOM_VSHIFT/10.0) *  (1 - BEZEL_INNER_ZOOM);
      

   }
   
   if (DO_DYNZOOM == 1.0) 
      coords = zoom(coords, get_dyn_zoom(avglum_pass));

   coords = zoom(coords, 1 + BEZEL_RFL_OFFSET * 0.05); 
   
   //eventually return black pixel
   if (coords.y < 0.0 || coords.y > 1.0 || coords.x < 0.0 || coords.x > 1.0) {
      FragColor = vec4(0.0);
      return;
   }


      
   //Create a gradient near borders to modulate between blurrend and sharp refection.
   //This also goes into output alpha channel to make the next pass aware of it.
   float smoothness = 0.08;
   float shade_sharp_blur = borders_gradient(vTexCoord, smoothness);
   shade_sharp_blur = shade_sharp_blur - BEZEL_RFL_BLR_SHD; //Modulates between sharp and blur via user parameter

      
   float shade_sharp_blur_adapted = shade_sharp_blur * 3.0;
   float lod0 = floor(shade_sharp_blur_adapted);
   float lod1 = lod0 + 1;
   vec3 s1 = textureLod( first_pass, coords, lod0).rgb;
   vec3 s2 = textureLod( first_pass, coords, lod1).rgb;
   float lodmix = fract(shade_sharp_blur_adapted);
   
   vec3 pixel_out = mix(s1, s2, lodmix);
   
   FragColor = vec4(pixel_out, 0.0);
}
 
 
  
