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

#include "functions.include"
void main() {

//vec3 bloom(float Directions, float Quality, float Size, float fbloom_gamma) {

    if (DO_AMBILIGHT == 1.0)
        FragColor = vec4 (bloom(bloom_directions,4,3,1.0), 0.0);
            else
        FragColor = vec4(0.0,0.0,0.0,1.0);
}
