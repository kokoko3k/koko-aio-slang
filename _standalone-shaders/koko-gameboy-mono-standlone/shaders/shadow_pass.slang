#version 450
#include "config.inc"

#define NTSC_FILTER_WIDTH_MAX 25
#define NTSC_FILTER_MIDDLE NTSC_FILTER_WIDTH/2

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 1) out vec3 vTemperature_rgb;
layout(location = 0) out vec2 vTexCoord;


#include "includes/functions.include.slang"


void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord * 1.0001;

   if (TEMPERATURE != 6500)
      vTemperature_rgb = kelvin2rgb(TEMPERATURE);
}


#pragma stage fragment

#include "includes/functions.include.slang"

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec3 vTemperature_rgb;


layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 2) uniform sampler2D Source;


void main() {
   vec3 pixel_out = texture(Source, vTexCoord).rgb;

   //Shadows
      if (DOT_M_SHADOW_STR > 0.0) {
         vec2 d = -vec2(params.SourceSize.z, params.SourceSize.w) * 0.5;
         vec3 pixel_offset;

       //  pixel_offset = texture(Source, vTexCoord +  vec2(DOT_M_SHADOW_OFF, abs(DOT_M_SHADOW_OFF)) * d).rgb;
 pixel_offset = texture(Source, vTexCoord +  vec2(DOT_M_SHADOW_OFF) * d).rgb;
         pixel_out = pixel_out - max( (pixel_out - pixel_offset), vec3(0.0) ) * DOT_M_SHADOW_STR;
   }


   FragColor = vec4(pixel_out, 1.0);

}


