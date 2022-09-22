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
layout(set = 0, binding = 4) uniform sampler2D avglum_pass;
layout(set = 0, binding = 5) uniform sampler2D avglum_passFeedback;

#define max_steps ambi_steps
#define min_steps 1.0
#define min_step_size 0.004 //roughly 1/255

float ambi_step(float start, float end, float mystep) {
    float diff = start-end;
    if (abs(diff) < mystep) return end;
    if (start >= end)
        return start - mystep;
            else
        return start + mystep;
}

vec3 ambi_step_rgb(vec3 s,vec3 d, vec3 mystep){
    //step fade (f) rom s to d
    vec3 f;
    f.r = ambi_step(s.r,d.r,mystep.r);
    f.g = ambi_step(s.g,d.g,mystep.g);
    f.b = ambi_step(s.b,d.b,mystep.b);
    return f;
}


vec3 pixel_ambilight() {
    float prev_avg_lum = texture(avglum_passFeedback,vec2(0.5,0.5)).a;
    float curr_avg_lum = texture(avglum_pass        ,vec2(0.5,0.5)).a;
    float diff_avg_lum = abs(prev_avg_lum - curr_avg_lum);

    vec3 previous_pixel = texture(PreviousSampler, vTexCoord).rgb;
    vec3 current_pixel =  texture(CurrentSampler, vTexCoord).rgb;

    vec3 mystep ;
    mystep = abs((previous_pixel-current_pixel) / max_steps);
    if (diff_avg_lum > scene_change_threshold ) mystep = vec3(1.0);
    
    vec3 outmix=ambi_step_rgb(previous_pixel,current_pixel,mystep);
    return outmix;
}


#include "functions.include.slang"
void main() {
    if (DO_AMBILIGHT != 1.0) return;
    FragColor = vec4(pixel_ambilight(),0.0);

}
