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


float smooth_step(float start, float end, float mystep) {

    float diff = start-end;
    if (abs(diff) < mystep) return end;
    if (start >= end)
        return start - mystep;
            else
        return start + mystep;
}

vec3 smooth_step_rgb(vec3 s,vec3 d, float mystep){
    //step fade (f) rom s to d
    vec3 f;
    f.r = smooth_step(s.r,d.r,mystep);
    f.g = smooth_step(s.g,d.g,mystep);
    f.b = smooth_step(s.b,d.b,mystep);
    return f;
}


vec3 pixel_ambilight() {
    vec3 prev_avg_lum_vec = texture(ambi_avglum_passFeedback,vec2(0.5,0.5)).rgb;
    vec3 curr_avg_lum_vec = texture(ambi_avglum_pass        ,vec2(0.5,0.5)).rgb;
    float prev_avg_lum = prev_avg_lum_vec.r+prev_avg_lum_vec.g+prev_avg_lum_vec.b;
    float curr_avg_lum = curr_avg_lum_vec.r+curr_avg_lum_vec.g+curr_avg_lum_vec.b;
    float diff_avg_lum = abs(prev_avg_lum - curr_avg_lum) / 3.0 ;

    float fade_speed = 0.05;
    float mystep = 0.004;
    if (diff_avg_lum > scene_change_threshold ) mystep = 1;

    if (diff_avg_lum > scene_change_threshold ) fade_speed = 1.0;

    vec3 previous_pixel = texture(PreviousSampler, vTexCoord).rgb;
    vec3 current_pixel =  texture(CurrentSampler, vTexCoord).rgb;

    //vec3 outmix = mix(previous_pixel,current_pixel,fade_speed);
    //outmix = smooth_step_rgb(outmix,current_pixel,mystep);

    //vec3 outmix = smooth_step_rgb(previous_pixel, current_pixel,mystep);
    //outmix = mix(outmix,current_pixel, fade_speed);


    vec3 outmix=smooth_step_rgb(previous_pixel,current_pixel,mystep);
    return outmix;
}


#include "functions.include"
void main() {
    if (DO_AMBILIGHT == 1.0)
        FragColor = vec4(pixel_ambilight(),0.0);
            else
        FragColor = vec4(0.0);
}
