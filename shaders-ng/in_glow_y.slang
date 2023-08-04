#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 2) out float vDoInGlowBias;


void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;  
   
   // If * at least one sharpness is lower than the max
   //    * we dont want just blur
   //    * we don't want to show ntsc artifact masks if we're doing ntsc artifacts
   // Then do in glow bias
   vDoInGlowBias = float (  IN_GLOW_BIAS < IN_GLOW_BIAS_MAX && 
                            (abs(IN_GLOW_W) < GLOW_SHARP_MAX || IN_GLOW_H < GLOW_SHARP_MAX) &&
                            (DO_NTSC_ARTIFACTS + NTSC_SHOW_ARTF_MASK < 1.5)   );
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 2) in float vDoInGlowBias;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 5) uniform sampler2D shift_and_bleed_pass;
layout(set = 0, binding = 6) uniform sampler2D Source;



#include "includes/functions.include.slang" 

vec3 glow_blur_bias(sampler2D source_tex, vec2 co, vec3 pixel_glowed, float bias){
   vec3 pixel_source = texture(source_tex, co).rgb;
   pixel_source  = pixel_source * IN_GLOW_POWER;
   
   vec3 glow_light = pixel_glowed - pixel_source;
   
   glow_light = clamp(glow_light * IN_GLOW_SPREAD, 0.0, 1.0);
  
   //glow_light = pow(glow_light, vec3(SERVICE1));
   
   vec3 proper_glow = glow_light * glow_light + pixel_source;  
   return mix(proper_glow, pixel_glowed, max(0.0, bias));   

}

/*
vec3 antialias_blur_bias(sampler2D source_tex, vec2 co, vec3 pixel_glowed, float bias){
   //Create a dilated and an eroded image, then mix between them via the blurred color.
   
   vec3 pixel_source = texture(source_tex, co).rgb;
   pixel_source  = pixel_source * IN_GLOW_POWER;
   
   vec3 glow_light = clamp((pixel_glowed - pixel_source) * IN_GLOW_SPREAD, 0.0, 1.0);

   vec3 pixel_glowed_inv = 1 - clamp(pixel_glowed, 0.0, 1.0);
   vec3 pixel_source_inv = 1 - clamp(pixel_source, 0.0, 1.0);
   
   vec3 pixel_dark = clamp((pixel_glowed_inv - pixel_source_inv) * IN_GLOW_SPREAD, 0.0, 1.0) ;

   vec3 pixel_dilated = pixel_source + glow_light ;
   vec3 pixel_eroded  = pixel_source - pixel_dark ;


   //Dilate or erode depending on blurred brightness:
      vec3 pixel_dilated_eroded =  mix(pixel_eroded, pixel_dilated, pixel_glowed);
   
   //Unsharp mask:
      float sharpamt = 0.5;
      pixel_dilated_eroded =  pixel_dilated_eroded + ((1 - pixel_glowed)*sharpamt);
      pixel_dilated_eroded = (pixel_dilated_eroded - sharpamt) * (1 + 2*sharpamt);

   
   return mix(pixel_dilated_eroded, pixel_glowed, max(0.0, bias));   
   //return mix(pixel_out, pixel_glowed, max(0.0, bias));   

}
*/

void main() { 
   if (DO_IN_GLOW == 0.0) {
      if ( DELTA_RENDER == 1.0) {
         float original_unchanged = texture(Source,vTexCoord).a;
         FragColor = vec4(1.0,1.0,1.0, original_unchanged);
         return;
      }
   }

   vec3 pixel_glowed;
   
   float IN_GLOW_H_ADAPTED = IN_GLOW_H;
   
   //GLow to blur via IN_GLOW_SPREAD:
      //Spread amount needs to lessen its influence when going from glow to blur
         float in_glow_spread = IN_GLOW_SPREAD * (1-IN_GLOW_BIAS);
         
      //Modulate sharpness via IN_GLOW_SPREAD when IN_GLOW_W is under minimum blur sharpness
         if (IN_GLOW_H <= MIN_IN_GLOW_SHARP)
            IN_GLOW_H_ADAPTED = in_glow_spread * IN_GLOW_SHARPNESS_SPREAD_RATIO_H;

   if (DO_NTSC_ARTIFACTS == 1.0) {
      float ntsc_artifacts = texture(shift_and_bleed_pass, vTexCoord).a;
      //finally "add" them to the configured sharpness (-> less blur)
      IN_GLOW_H_ADAPTED = IN_GLOW_H_ADAPTED +  ((1-ntsc_artifacts) * NTSC_ARTF_NOBLUR);
   }
   
   //don't allow lower values that look bad:
      IN_GLOW_H_ADAPTED = max(IN_GLOW_H_ADAPTED, MIN_IN_GLOW_SHARP);

   //Make it resolution independent.
      IN_GLOW_H_ADAPTED = IN_GLOW_H_ADAPTED / NEW_SCALEMOD_X;
   
   
   
   //It over the max sharp, then just passthrough, else do the blur.
      if (IN_GLOW_H >= GLOW_SHARP_MAX) {
         pixel_glowed = texture(Source,vTexCoord).rgb * IN_GLOW_POWER;
      } else {
         pixel_glowed = blur9_y(Source, vTexCoord, params.SourceSize.xy, IN_GLOW_H_ADAPTED) * IN_GLOW_POWER;
      }
   
   
   //Series of conditions to do in glow bias done in vertex shader:
      if (vDoInGlowBias == 1.0) {
            pixel_glowed = glow_blur_bias(shift_and_bleed_pass, vTexCoord, pixel_glowed, IN_GLOW_BIAS);
            //pixel_glowed = antialias_blur_bias(shift_and_bleed_pass, vTexCoord, pixel_glowed, IN_GLOW_BIAS);
      }
   
   //Previous pass compared previous and current source frame and exported that info in the alpha.
   //Pass it through when we need delta rended.
      if ( DELTA_RENDER == 1.0) {
         float original_unchanged = texture(Source,vTexCoord).a;
         FragColor = vec4(pixel_glowed, original_unchanged);
         return;
      }
   
   FragColor = vec4(pixel_glowed,1.0);
   
}

