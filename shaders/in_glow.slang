#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 inglow_wh_vec2;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;
   // Blur radius must not depend on input resolution
   inglow_wh_vec2 = vec2(IN_GLOW_WH * (320.0/params.OutputSize.x), IN_GLOW_WH * (224.0/params.OutputSize.x));
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 inglow_wh_vec2;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 3) uniform sampler2D FXAA_pass;
layout(set = 0, binding = 4) uniform sampler2D first_pass;

// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "includes/pixel_glows.include.slang" 

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
         pixel_glowed = pixel_glow(FXAA_pass, inglow_wh_vec2.x,inglow_wh_vec2.y,IN_GLOW_POWER,IN_GLOW_GAMMA,vTexCoord, params.OutputSize, params.OutputSize).rgb;
            else
         pixel_glowed = pixel_glow(first_pass, inglow_wh_vec2.x,inglow_wh_vec2.y,IN_GLOW_POWER,IN_GLOW_GAMMA,vTexCoord, params.OutputSize, params.OutputSize).rgb;
         
         if (IN_GLOW_ADD>0.0) pixel_glowed = mix(pixel_glowed,pixel_out+pixel_glowed,IN_GLOW_ADD);
         pixel_out = pixel_glowed;
   }

   FragColor = vec4((pixel_out),1.0);
}

