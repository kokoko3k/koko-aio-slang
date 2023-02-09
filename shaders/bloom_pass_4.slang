#version 450

// This is one of several passes needed to cheaply emulate the bloom effect.

#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#include "includes/functions.include.slang"
#include "includes/blooms.include.slang"

#define offset 0.5890486225480862 // TAU/8.0/4.0*3.0

void main() {
    if (DO_BLOOM == 0.0) return;

    vec3 bloomed = bloom(
        Source,
        vTexCoord,
        params.SourceSize,
        vec2(BLOOM_SIZE),
        BLOOM_QUALITY,
        offset,
        0.0
    );
    
    bloomed = pow(bloomed,vec3(BLOOM_GAMMA_OUT));
    bloomed*=BLOOM_POWER;
    bloomed = pixel_push_luminance(bloomed, BLOOM_POWER);
    FragColor = vec4(bloomed, 1.0); //FragColor = texture(Source,vTexCoord);

}
