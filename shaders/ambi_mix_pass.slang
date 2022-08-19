#version 450
#include "config.inc"
#define noisepower 0.015

#define eps 1e-8

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;

#include "functions.include"
void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = get_scaled_coords(TexCoord);
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
    vec3 ambi = texture(ambi_temporal_pass, vOutputCoord).rgb;
    float l = length(ambi);
    float sat = 1.5;
    ambi =  normalize( pow(ambi.rgb + vec3(eps), vec3(sat)))*l  ;
    return vec4(ambi,0.0);
}

vec3 mixed() {
    float noise = random() * noisepower;
    return pixel_border().rgb + vec3(noise);
}

#include "functions.include"
void main() {
    vec4 psample = texture(Source, vOutputCoord);
    if (DO_AMBILIGHT == 1) {
        if (is_outer_frame(psample)) {
            FragColor = mark_outer_frame(mixed());
        } else {
            FragColor = psample;
        }
    } else {
        FragColor = psample ;
    }
}
