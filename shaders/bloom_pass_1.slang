#version 450
#include "config.inc"

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

#define SourceTexture Source
#define SourceTextureSize params.SourceSize


// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "blooms.slang" 


void main() {

//vec4 bloom_new(sampler2D tex, vec2 coords, vec2 size, float samples, float quality) {

float size = 3;
int samples = 9;
float quality = 4.0;
float threshold = 0.5;

//FragColor = vec4(bloom_new(SourceTexture, vTexCoord, size, quality, BLOOM_THRESHOLD), 1.0);
//return;

    if (DO_BLOOM == 1.0 ) {
        vec3 bloomed = bloom(bloom_directions,bloom_quality,bloom_size,bloom_gamma) * bloom_power;
        //vec3 bloomed = bloom_new(SourceTexture, vTexCoord, bloom_size, bloom_quality, BLOOM_THRESHOLD) * bloom_power;
        FragColor = vec4(pow(bloomed,vec3(bloom_gamma_out)),1.0);
    } else {
        return ;
    }
}
