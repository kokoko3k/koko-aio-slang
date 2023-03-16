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

layout(set = 0, binding = 1) uniform sampler2D Source;
layout(set = 0, binding = 2) uniform sampler2D avglum_pass;

#include "includes/functions.include.slang"

float circle_smooth(vec2 coords, vec2 middle, float f_radius, float FALLOFF) {
   //Draw a circle with smoothed borders:
   float fdistance=distance(middle, vec2(coords.x, coords.y));
   float circle = (1-smoothstep(f_radius-FALLOFF, f_radius+FALLOFF, fdistance));
   return circle;
}

float square_smooth(vec2 co, vec2 corner, float size, float smoothshade) {
   //Draws a square with smooth borders:
   vec4 rect = vec4(corner.x, corner.y, corner.x+size, corner.y+size);
   vec2 hv = smoothstep(rect.xy - smoothshade, rect.xy, co) * smoothstep(co - smoothshade, co, rect.zw);
   return  hv.x * hv.y;
}

float corners_shade(vec2 co, float size, float smoothsize){
   //Draws 4 smooth squares or circles in the corners.
   //They are intended to modulate the blur radius and the strength of the reflection.
   
   /*
      vec4 circles;
      float circle_radius = size; //0.13?
      float circle_falloff = smoothsize; //0.05?
      float circle_power =2.0;
      circles.x = circle_smooth(co, vec2(0.0,0.0), circle_radius, circle_falloff) * circle_power;
      circles.y = circle_smooth(co, vec2(0.0,1.0), circle_radius, circle_falloff) * circle_power;
      circles.z = circle_smooth(co, vec2(1.0,0.0), circle_radius, circle_falloff) * circle_power;
      circles.w = circle_smooth(co, vec2(1.0,1.0), circle_radius, circle_falloff) * circle_power;
               
      float circle = max(max(max(circles.x, circles.y), circles.z), circles.w);
      circle = min(circle, 1.0);
      circle = 1-circle;
      
      return circle;
   */      
   vec4 squares;
   float squaresize = size;
   float squarefade = smoothsize;
   //(vec2 co, vec2 corner, float size, float smoothshade) {
   squares.x = square_smooth(co, vec2(0.0,0.0), squaresize, squarefade);
   squares.y = square_smooth(co, vec2(1.0 - squaresize, 0.0), squaresize, squarefade);
   squares.z = square_smooth(co, vec2(0.0, 1-squaresize), squaresize, squarefade);
   squares.w = square_smooth(co, vec2(1-squaresize, 1-squaresize), squaresize, squarefade);
   return max(max(max(squares.x, squares.y), squares.z), squares.w);
}

float borders_gradient(vec2 co, float smoothness) {
   //Draws a square with smooth borders:
   float size = 1.0;
   vec4 rect = vec4(0.0+smoothness, 0.0+smoothness, size - smoothness, size - smoothness);
   vec2 hv = smoothstep(rect.xy - smoothness, rect.xy, co) * smoothstep(co - smoothness, co, rect.zw);
   return  hv.x * hv.y;
}

void main() {
   
   if (DO_BEZEL == 0.0) return;

   float skip_border = BEZEL_REFL_SKIP_SIZE / BEZEL_REFL_ZOOMOUT_ROOM ;
   if (vTexCoord.x > skip_border && vTexCoord.x < 1.0 - skip_border &&
       vTexCoord.y > skip_border && vTexCoord.y < 1.0 - skip_border ) {
      FragColor = vec4(0.0);
      return;
   }   

   //Zoom out the image coordinates by the bezel border size to make room for reflections:
      vec2 coords = zoom(vTexCoord, BEZEL_REFL_ZOOMOUT_ROOM);
   



   //Create gradients in the corners to fadeout reflections and to blur more near them:
      float fcorners_shade = corners_shade(vTexCoord, BEZEL_REFL_CORNER_BLANK_SIZE, BEZEL_REFL_CORNER_BLANK_SHADE);
     
   //Create a gradient near borders to modulate between blurrend and sharp refection.
   //This also goes into output alpha channel to make the next pass aware of it.
   float smoothness = 0.11;
   float shade_sharp_blur = borders_gradient(vTexCoord, smoothness);
   shade_sharp_blur = 1 - (shade_sharp_blur + BEZEL_RFL_BLR_SHD); //Modulates between sharp and blur via user parameter

   //Also modulate in the corners via fcorners_shade (fcorners_shade 
      shade_sharp_blur = max(fcorners_shade, shade_sharp_blur);
      
   float shade_sharp_blur_adapted = shade_sharp_blur * 3.5;      
   float lod0 = floor(shade_sharp_blur_adapted);
   float lod1 = lod0 + 1;
   vec3 s1 = textureLod( Source, coords, lod0).rgb;
   vec3 s2 = textureLod( Source, coords, lod1).rgb;
   float lodmix = fract(shade_sharp_blur_adapted);
   
   vec3 pixel_out = mix(s1, s2, lodmix);
   
   //multiply the blurred image by the corner shade so that reflections will not be visible in the corners.
      pixel_out = pixel_out * (1 - fcorners_shade);
   
   pixel_out = apply_fuzzy_main_pass(pixel_out);
   
   
   
   FragColor = vec4(pixel_out, 0.0);
   
   //FragColor = vec4(shade_sharp_blur_adapted);
   
}
 
 
  
