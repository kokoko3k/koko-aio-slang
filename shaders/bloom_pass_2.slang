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

vec3 pow3(vec3 v, float fpow) {
     
    //Depending on the hardware and shader compiler (and maybe on the exponent)
    //one may prefer to use the default pow or the integer optimized one.
    if (prefer_std_pow == 1) {
        return pow(v,vec3(fpow));
    }
    
    vec3 v2,v4;
    if (fpow == 1) {
        return v;
    } else if (fpow == 2) {
        return v*v;
        
    } else if (fpow == 3) {
        return v*v*v;
        
    } else if (fpow == 4) {
        v2=v*v;
        return v2*v2;
        
    } else if (fpow == 5) {
        v2=v*v;
        return v2*v2*v;
        
    } else if (fpow == 6) {
        v2=v*v;
        return v2*v2*v2;
        
    } else if (fpow == 7) {
        v2=v*v;
        return v2*v2*v2*v;
        
    } else if (fpow == 8) {
        v2=v*v;
        v4=v2*v2;
        return v4*v4;
        
    } else if (fpow == 9) {
        v2=v*v;
        v4=v2*v2;
        return v4*v4*v;
        
    } else if (fpow == 10) {
        v2=v*v;
        v4=v2*v2;
        vec3 v8=v4*v4;
        return v8*v2;        
    }
}

// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "blooms.slang" 


void main() {
    if (DO_BLOOM > 0.0 ) {
        FragColor = vec4(bloom(bloom_directions,bloom_quality,bloom_size,1),0.0);
    } else {
        FragColor = texture( SourceTexture, vTexCoord);
    }
}
