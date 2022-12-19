#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out float vInGlowBias;


void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;  
   //vInGlowBias = pow(IN_GLOW_BIAS,0.9);
   vInGlowBias = IN_GLOW_BIAS + 1;
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float vInGlowBias;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 3) uniform sampler2D FXAA_pass;
layout(set = 0, binding = 4) uniform sampler2D first_pass;
layout(set = 0, binding = 5) uniform sampler2D shift_and_bleed_pass;


// Blur sizes must not depend on input resolution
#define scalemod_x (params.OutputSize.x/360.0)
#define scalemod_y (params.OutputSize.y/270.0)

// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "includes/pixel_glows.include.slang" 


vec3 glow_blur_bias(sampler2D source_tex, vec2 co, vec3 pixel_glowed, float bias) {
   //from latitude. with pow.
   vec3 pixel_source = texture(source_tex, co).rgb;
   pixel_source  = pow(pixel_source,vec3(IN_GLOW_GAMMA)) * IN_GLOW_POWER;
   
   float glowlum = max(max(pixel_glowed.r, pixel_glowed.g), pixel_glowed.b);
   float orilum =  max(max(pixel_source.r, pixel_source.g), pixel_source.b);
   glowlum = clamp(glowlum, 0.0, 1.0);
   orilum =  clamp(orilum, 0.0, 1.0);
   float g_mix = (glowlum - orilum);
   g_mix += IN_GLOW_BIAS;
   g_mix = clamp(g_mix, 0.0, 1.0);
   return mix(pixel_source, pixel_glowed, g_mix);
}


void main() { 
 
   
   
   if (DO_IN_GLOW == 0.0) return;
   
   vec3 pixel_glowed;
   if ( DO_SHIFT_RGB + DO_SAT_BLEED > 0.0) {
      pixel_glowed = pixel_glow(shift_and_bleed_pass, IN_GLOW_W, IN_GLOW_H, IN_GLOW_POWER, IN_GLOW_GAMMA, vTexCoord, params.OutputSize, params.OutputSize).rgb;
       if (IN_GLOW_BIAS < IN_GLOW_BIAS_MAX && (IN_GLOW_W < GLOW_SHARP_MAX || IN_GLOW_H < GLOW_SHARP_MAX) )
          pixel_glowed = glow_blur_bias(shift_and_bleed_pass, vTexCoord, pixel_glowed, IN_GLOW_BIAS);
      
      }
   else if (DO_FXAA > 0.0) {
      pixel_glowed = pixel_glow(FXAA_pass, IN_GLOW_W, IN_GLOW_H, IN_GLOW_POWER, IN_GLOW_GAMMA, vTexCoord, params.OutputSize, params.OutputSize).rgb;
       if (IN_GLOW_BIAS < IN_GLOW_BIAS_MAX &&  (IN_GLOW_W < GLOW_SHARP_MAX || IN_GLOW_H < GLOW_SHARP_MAX) )
          pixel_glowed = glow_blur_bias(FXAA_pass, vTexCoord, pixel_glowed, IN_GLOW_BIAS);
      
   }
   else {
      pixel_glowed = pixel_glow(first_pass, IN_GLOW_W, IN_GLOW_H, IN_GLOW_POWER, IN_GLOW_GAMMA, vTexCoord, params.OutputSize, params.OutputSize).rgb;
      if (IN_GLOW_BIAS < IN_GLOW_BIAS_MAX &&  (IN_GLOW_W < GLOW_SHARP_MAX || IN_GLOW_H < GLOW_SHARP_MAX) )
          pixel_glowed = glow_blur_bias(first_pass, vTexCoord, pixel_glowed, IN_GLOW_BIAS);
      
   }



   FragColor = vec4((pixel_glowed),1.0);
}

