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
    if (DO_BLOOM == 1.0 ) {
        vec3 bloomed = bloom(bloom_directions,bloom_quality,bloom_size,bloom_gamma) * bloom_power;
        FragColor = vec4(pow(bloomed,vec3(bloom_gamma_out)),1.0);
    } else {
        return ;
    }
}
