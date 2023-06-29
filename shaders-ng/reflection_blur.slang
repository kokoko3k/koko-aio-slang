#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vFuzzy_main_pass_stage_1;

#include "includes/functions.include.slang"
#include "includes/blooms.include.slang"

void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;

   //Get fuzzy mul and pow factor
      vFuzzy_main_pass_stage_1 = apply_fuzzy_main_pass_stage_1();   
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vFuzzy_main_pass_stage_1;

layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 1) uniform sampler2D Source;
layout(set = 0, binding = 2) uniform sampler2D flick_and_noise_pass;
layout(set = 0, binding = 3) uniform sampler2D reflected_blurred_passFeedback;

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

   
   //Zoom out the image coordinates by the bezel border size to make room for reflections:
      vec2 coords = zoom(vTexCoord, BEZEL_REFL_ZOOMOUT_ROOM);
   
   //Skip unuseful pixels
      float skip_border = BEZEL_REFL_SKIP_SIZE;
      if (coords.x > skip_border && coords.x < 1.0 - skip_border &&
         coords.y > skip_border && coords.y < 1.0 - skip_border ) {
         FragColor = vec4(0.0);
         return;
      }
/*
   //Create a gradient near borders to modulate between blurrend and sharp refection.
      float smoothness = 0.11;
      float shade_sharp_blur = borders_gradient(vTexCoord, smoothness);
      shade_sharp_blur = 1.05 - (shade_sharp_blur + BEZEL_RFL_BLR_SHD); //Modulates between sharp and blur via user parameter
*/
      
      
      
      float shade_sharp_blur = texture(Source, coords).a;
      
      
      
   //Create gradients in the corners to blur more more near corners:
      #define CORNER_BLURRINESS 0.6
      float fcorners_shade = corners_shade(vTexCoord, 0.9) * CORNER_BLURRINESS;
      shade_sharp_blur = max(fcorners_shade, shade_sharp_blur);
 /*     
   //Sample a lod and the next integer one, then do a linear smapling between them
   //to blur the reflections as they goes far from the tube.
      float shade_sharp_blur_adapted = shade_sharp_blur * 5.5;
      float lod0 = floor(shade_sharp_blur_adapted);
      float lod1 = lod0 + 1;
      vec3 s1 = textureLod( Source, coords, lod0).rgb;
      vec3 s2 = textureLod( Source, coords, lod1).rgb;
      float lodmix = fract(shade_sharp_blur_adapted);
      vec3 pixel_out = mix(s1, s2, lodmix) * BEZEL_REFL_STRENGTH;
*/
 
      
      float blur_radius=   (shade_sharp_blur) * 3.5  ;
      blur_radius = clamp(blur_radius, 1.0, 100.0);
      
      //FragColor = vec4(shade_sharp_blur); return;
      
      //      FragColor = texture(Source, coords);return;
      
      
      
      float blur_quality = 1;

      float start_offset = (pi*2.0/8.0/4.0);

      vec3 pixel_out = bloom(Source, coords, global.FinalViewportSize, vec2(blur_radius), blur_quality, start_offset, 0.0) ;
      pixel_out *= BEZEL_REFL_STRENGTH;
 
   //Next simulate a diffused light
      vec3 pixel_diffused = textureLod( flick_and_noise_pass, coords, 6.0).rgb;
      pixel_out = mix( pixel_out, pixel_diffused, BEZEL_DIFFUSION_STR);
      
   
   //multiply the blurred image by the corner shade so that reflections will not be visible in the corners.
   //This has been moved to final pass because it didn't worked well with curvature
   //at 0.0 inner zoom level.
      //pixel_out = pixel_out * (1 - fcorners_shade);

   pixel_out = apply_fuzzy_main_pass_stage_2(pixel_out, vFuzzy_main_pass_stage_1);
   
   vec3 pixel_out_fb =  texture(reflected_blurred_passFeedback, vTexCoord).rgb;
   pixel_out = mix(pixel_out_fb.rgb, pixel_out, 0.5 );
   

   FragColor = vec4(pixel_out, 1.0); 
   
   //FragColor = vec4(shade_sharp_blur);

}
 
 
  
