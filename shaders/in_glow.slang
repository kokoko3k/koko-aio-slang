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
   vInGlowBias = pow(IN_GLOW_BIAS,0.9);
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

vec3 OLD_glow_blur_bias(sampler2D source_tex, vec2 co, vec3 pixel_glowed, float bias) {
   vec3 pixel_source = texture(source_tex, co).rgb;
   
   vec3 pixel_glowed_c = clamp(pixel_glowed, 0.0, 1.0);
   vec3 pixel_source_c = clamp(pixel_source, 0.0, 1.0);
   vec3 vmix = vec3( pixel_glowed_c.r - pixel_source_c.r,
                     pixel_glowed_c.g - pixel_source_c.g,
                     pixel_glowed_c.b - pixel_source_c.b);
   
   //vmix = clamp(vmix, 0.0, 1.0);
   vmix += IN_GLOW_BIAS;
   return mix(pixel_source, pixel_glowed, vmix);
}

vec3 glow_blur_bias(sampler2D source_tex, vec2 co, vec3 pixel_glowed, float bias) {
   //Modulates the mix of the blurred version over the sharp one
   //by the luminosity difference of the blurred version and the original
   vec3 pixel_original = texture(source_tex,vTexCoord).rgb;
   vec3 pixel_sharp  = pow(pixel_original,vec3(IN_GLOW_GAMMA)) * IN_GLOW_POWER;
   
   vec3 pixel_glowed_c = clamp(pixel_glowed, 0.0, 1.0);
   vec3 pixel_sharp_c = clamp(pixel_sharp, 0.0, 1.0);
   
   vec3 vmix = vec3( pixel_glowed_c.r - pixel_original.r,
                     pixel_glowed_c.g - pixel_original.g,
                     pixel_glowed_c.b - pixel_original.b);

   vmix = clamp(vmix, 0.0, 1.0);
   return mix(pixel_sharp, pixel_glowed, clamp(   (vmix+0.01 * vInGlowBias) , 0.0,1.0)   );
}

void main() { 
 
   
   
   if (DO_IN_GLOW == 0.0) return;
   
   vec3 pixel_glowed;
   if ( DO_SHIFT_RGB + DO_SAT_BLEED > 0.0) {
      pixel_glowed = pixel_glow(shift_and_bleed_pass, IN_GLOW_WH,IN_GLOW_WH,IN_GLOW_POWER,IN_GLOW_GAMMA,vTexCoord, params.OutputSize, params.OutputSize).rgb;
      if (IN_GLOW_BIAS < 100.0 && IN_GLOW_WH < GLOW_SHARP_MAX )
         pixel_glowed = glow_blur_bias(shift_and_bleed_pass, vTexCoord, pixel_glowed, IN_GLOW_BIAS);
      }
   else if (DO_FXAA > 0.0) {
      pixel_glowed = pixel_glow(FXAA_pass, IN_GLOW_WH,IN_GLOW_WH,IN_GLOW_POWER,IN_GLOW_GAMMA,vTexCoord, params.OutputSize, params.OutputSize).rgb;
      if (IN_GLOW_BIAS < 100.0 && IN_GLOW_WH < GLOW_SHARP_MAX)
         pixel_glowed = glow_blur_bias(FXAA_pass, vTexCoord, pixel_glowed, IN_GLOW_BIAS);
   }
   else {
      pixel_glowed = pixel_glow(first_pass, IN_GLOW_WH,IN_GLOW_WH,IN_GLOW_POWER,IN_GLOW_GAMMA,vTexCoord, params.OutputSize, params.OutputSize).rgb;
      if (IN_GLOW_BIAS < 100.0 && IN_GLOW_WH < GLOW_SHARP_MAX)
         pixel_glowed = glow_blur_bias(first_pass, vTexCoord, pixel_glowed, IN_GLOW_BIAS);
   }



   FragColor = vec4((pixel_glowed),1.0);
}

