#version 450
#include "config.inc"

#define PreviousSampler ambi_temporal_passFeedback
#define CurrentSampler ambi_pre_pass1

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

layout(set = 0, binding = 4) uniform sampler2D ambi_avglum_pass;
layout(set = 0, binding = 5) uniform sampler2D ambi_avglum_passFeedback;



vec3 pixel_ambilight() {
    vec3 prev_avg_lum_vec = texture(ambi_avglum_passFeedback,vec2(0.5,0.5)).rgb;
    vec3 curr_avg_lum_vec = texture(ambi_avglum_pass        ,vec2(0.5,0.5)).rgb;
    float prev_avg_lum = prev_avg_lum_vec.r+prev_avg_lum_vec.g+prev_avg_lum_vec.b;
    float curr_avg_lum = curr_avg_lum_vec.r+curr_avg_lum_vec.g+curr_avg_lum_vec.b;
    float diff_avg_lum = abs(prev_avg_lum - curr_avg_lum) / 3.0 ;

    float fade_speed = 0.05;

    if (diff_avg_lum > scene_change_threshold ) fade_speed = 1.0;

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
