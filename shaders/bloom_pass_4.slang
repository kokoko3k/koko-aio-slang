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
#include "includes/blooms.include.slang" 

#define B_DIRECTIONS (bdirections)
#define B_QUALITY    (BLOOM_QUALITY)
#define B_SIZE       (BLOOM_SIZE * (params.SourceSize.x/320.0) )

void main() {

    if (DO_BLOOM == 1.0 ) {
        vec3 bloomed = (bloom(bloom_directions,BLOOM_QUALITY,BLOOM_SIZE,1));
        //vec3 bloomed = bloom_new(SourceTexture, vTexCoord, BLOOM_SIZE, BLOOM_QUALITY, BLOOM_THRESHOLD) * BLOOM_POWER;
        FragColor = vec4(pow(bloomed,vec3(BLOOM_GAMMA_OUT)),1.0);
    } else {
        return;
    }
}
