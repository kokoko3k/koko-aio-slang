#version 450
#include "config.inc"
#define eps 1e-5
#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D first_pass;
layout(set = 0, binding = 3) uniform sampler2D avglum_pass;

#include "includes/functions.include.slang"

void main() {
   if (DO_AMBILIGHT != 1.0) return; 
   
   vec3 pixel_out = texture(first_pass, vTexCoord).rgb;
   pixel_out = apply_fuzzy_main_pass(pixel_out);
   if (AMBI_POWER > 1.0) {
      float avglum = texture(avglum_pass, vTexCoord).a;
   
      //push input brightness but not too much for already brighter images.
      float push =  AMBI_POWER * (1.0 - avglum)  + 1.0;
      pixel_out = pixel_out * push;

      //Compensate for the loss of SATURATION
      float extrasat = min(push,2.0); //not more than 2X
      float l = length(pixel_out);
      pixel_out =  normalize( pow(pixel_out.rgb + vec3(eps), vec3(extrasat)))*l  ;
   } else {
      pixel_out = pixel_out * AMBI_POWER;
   }
   
   FragColor = vec4(pixel_out,1.0);
   
   
   
}
