#version 450
#include "config.inc"

#define PreviousSampler ambi_temporal_passFeedback
#define CurrentSampler Source

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
layout(set = 0, binding = 2) uniform sampler2D CurrentSampler;
layout(set = 0, binding = 3) uniform sampler2D PreviousSampler;
layout(set = 0, binding = 6) uniform sampler2D ambi_pre_pass1;


vec3 pixel_ambilight() {
    /*vec3 pref = texture(get_avg_lum_passFeedback, vTexCoord).rgb;
    vec3 cref  = texture(get_avg_lum_pass, vTexCoord).rgb;
    float ref_diff = abs( ((pref.r+pref.g+pref.b)/3) - ((cref.r+cref.g+cref.b)/3) );
    */
    float fade_speed = 0.03;
    //if (ref_diff > 0.1) fade_speed = 0.5;
    vec3 previous_pixel = texture(PreviousSampler, vTexCoord).rgb;
    vec3 current_pixel =  texture(CurrentSampler, vTexCoord).rgb;
    vec3 outmix = mix(previous_pixel,current_pixel,fade_speed);
    return outmix;
}



#include "functions.include"
void main() {
    if (DO_AMBILIGHT == 1.0)
        FragColor = vec4(pixel_ambilight(),0.0);
            else
        FragColor = vec4(0.0);
}
