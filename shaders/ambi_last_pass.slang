#version 450
#include "config.inc"

#define PreviousSampler dowscale_4ambi_passFeedback

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
layout(set = 0, binding = 2) uniform sampler2D Original;
layout(set = 0, binding = 3) uniform sampler2D PreviousSampler;

#define SourceTexture Original
#define SourceTextureSize params.OriginalSize

// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "blooms.slang" 

vec3 pixel_ambilight() {
    vec3 previous_pixel = texture(PreviousSampler, vTexCoord).rgb;
    //vec3 bloom(float Directions, float Quality, float Size, float fbloom_gamma) {
    vec3 blurred = (bloom(bloom_directions,40,40,1));
    
    //vec3 blurred = texture(Original,vTexCoord).rgb;
    
    vec3 outmix = mix(previous_pixel,blurred,0.03);

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

    if (DO_AMBILIGHT == 1) {
        FragColor = vec4(pixel_ambilight(),1.0);
    } else {
        FragColor = vec4(0.0,0.0,0.0,1.0);
    }
}
