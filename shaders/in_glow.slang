#version 450

#include "config.inc"


#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;


void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;  
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 3) uniform sampler2D FXAA_pass;
layout(set = 0, binding = 4) uniform sampler2D first_pass;


// Blur sizes must not depend on input resolution
#define scalemod_x (params.SourceSize.x/360.0)
#define scalemod_y (params.SourceSize.y/270.0)

// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "pixel_glows.include.slang" 
#include "functions.include.slang"

void main() { 
   //FIXME: flickering scanlines does not curve, and think they will never do due to moiree, not a big deal since they are barely visible.

   vec3 pixel_out;
   //Use to debug:
      //FragColor=vec4(abs(sin(params.FrameCount/3.14/20))); //white fade
      //FragColor=vec4(abs(sin(params.FrameCount/3.14/20)),0.0,0.0,0.0); //red fade
      //FragColor=vec4(0.8);
      //if  (mod(params.FrameCount,10) == 0) FragColor=vec4(0.0) ; else FragColor=vec4(1.0);
      //return;

   
   if (DO_IN_GLOW == 0.0) return;
   
   if (DO_FXAA == 1.0)
      pixel_out = texture(FXAA_pass, vTexCoord).rgb;
         else
      pixel_out = texture(first_pass, vTexCoord).rgb;

   if (DO_IN_GLOW == 1.0) {
      vec3 pixel_glowed;
      if (DO_FXAA == 1.0)
         pixel_glowed = pixel_glow(FXAA_pass, IN_GLOW_WH,IN_GLOW_WH,IN_GLOW_POWER,IN_GLOW_GAMMA,vTexCoord, global.FXAA_passSize, global.FXAA_passSize).rgb;
            else
         pixel_glowed = pixel_glow(first_pass, IN_GLOW_WH,IN_GLOW_WH,IN_GLOW_POWER,IN_GLOW_GAMMA,vTexCoord, global.FXAA_passSize, global.FXAA_passSize).rgb;
         
         if (IN_GLOW_ADD>0.0) pixel_glowed = mix(pixel_glowed,pixel_out+pixel_glowed,IN_GLOW_ADD);
         pixel_out = pixel_glowed;
   }

   FragColor = vec4((pixel_out),1.0);
}

