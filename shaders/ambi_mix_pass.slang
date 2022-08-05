#version 450
#include "config.inc"
#define noisepower 0.015


#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;

void main()
{
   gl_Position = global.MVP * Position;

   float scale_x = params.OutputSize.x/(in_aspect * params.OutputSize.y);
   float scale_y = 1.0;
   float offset_x = (0.5 * scale_x ) - 0.5 ;
   
   vec2 scale_coord=vec2(TexCoord.x*scale_x - offset_x,TexCoord.y*scale_y);
   
   vTexCoord = scale_coord;
   vOutputCoord = TexCoord;
}


#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;
layout(set = 0, binding = 4) uniform sampler2D ambi_temporal_pass;


float random() {
    // www.stackoverflow.com/questions/5149544/can-i-generate-a-random-number-inside-a-pixel-shader/
    vec2 seed = vTexCoord * params.FrameCount;
    vec2 i = vec2(23.140692, 2.6651442);
    return fract(cos(dot(seed, i)) * 123456.0f);
}


vec4 pixel_border() {
    return texture(ambi_temporal_pass, vOutputCoord);
}


#include "functions.include"
void main() {
    vec4 psample = texture(Source, vOutputCoord);
    if (is_outer_frame(psample)) {
        float noise = random() * noisepower;
        vec3 myborder = pixel_border().rgb + vec3(noise);
        FragColor = mark_outer_frame(myborder);
    } else {
        FragColor = psample;
    }
}
