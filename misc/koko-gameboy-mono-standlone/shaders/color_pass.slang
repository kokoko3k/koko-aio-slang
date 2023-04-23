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
layout(set = 0, binding = 3) uniform sampler2D color_passFeedback;


void main() {
   vec3 pixel_out = texture(Source, vTexCoord).rgb;


   //Colorize:
      pixel_out = color_tools(pixel_out, vTemperature_rgb);

   //Motion blur / ghosting
      if (DOT_M_MBLUR_STR > 1.0) {
         vec3 feedback = texture(color_passFeedback, vTexCoord).rgb;

         vec3 m_blur_adapted = vec3(DOT_M_MBLUR_STR);
         if (DOT_M_MBLUR_MODE > 0.0) {
            vec3 adaption = mix_step (pixel_out - feedback,
                                       feedback - pixel_out,
                                       DOT_M_MBLUR_MODE -1);

            m_blur_adapted *= clamp( adaption, 0.0, 1.0 );
            m_blur_adapted = pow(m_blur_adapted, vec3(0.25));
         }
         pixel_out = mix(pixel_out, feedback, m_blur_adapted);
      }


   FragColor = vec4(pixel_out, 1.0);

}


