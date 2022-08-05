#version 450
#include "config.inc"

#define PreviousSampler ambi_temporal_passFeedback

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
layout(set = 0, binding = 2) uniform sampler2D Source;
layout(set = 0, binding = 3) uniform sampler2D PreviousSampler;


vec3 pixel_ambilight() {
    vec3 previous_pixel = texture(PreviousSampler, vTexCoord).rgb;
    vec3 current_pixel =  texture(Source, vTexCoord).rgb;
    
    vec3 outmix = mix(previous_pixel,current_pixel,0.03);
    return outmix;
}


#include "functions.include"
void main() {
/*    vec4 psample = texture(Original, vTexCoord);
    if (is_outer_frame(psample))
        FragColor = mark_outer_frame(vec3(0.5));
            else
        FragColor = psample;
*/ 



    FragColor = vec4(pixel_ambilight(),0.0);
}
