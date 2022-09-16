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

void main() {
    vec4 pixel_out;
    if (DO_AMBILIGHT == 1.0 || DO_BEZEL == 1.0) {
        if (DO_AMBILIGHT == 1.0) pixel_out.rgb = textureLod(Source, vec2(0.5,0.5),20.0).rgb;
        
        if (DO_BEZEL == 1.0) {
            //Create a small mipmap to be used to light the bezel corners.
            //iterate through lods 'till we find a small-enough texture
            //put the luminosity into the alpha channel to spare a pass.
            float min_w = 16; //16 pixel wide or less
            float lod = log2(params.SourceSize.y / min_w);
            vec3 lut = textureLod(Source, vTexCoord,lod ).rgb;
            pixel_out.a = (lut.r+lut.g+lut.b)/3.0;
        }
        FragColor = pixel_out;
        
    }
}
