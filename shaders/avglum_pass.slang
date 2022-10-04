#version 450
#include "config.inc"

//16 pixel wide for the mipmap.
#define min_w 16 

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out float lod;
void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   lod = log2(params.SourceSize.y / min_w);
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float lod;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;



void main() {
    /*Grab a mipmap from the previous pass.
      Calculate the average luminance from the smallest mipmap and put into the alpha channel
      So that can be used by the scene detection logic.
      Put another small mipmap into the rgb channel to be used by the reflection code.
    */
    vec4 pixel_out;
    if (DO_AMBILIGHT == 1.0 || DO_BEZEL == 1.0) {
        if (DO_AMBILIGHT == 1.0)  {
            //pixel_out.rgb = textureLod(Source, vec2(0.5,0.5),20.0).rgb;
            vec4 mip = textureLod(Source, vec2(0.5,0.5),20.0);
            pixel_out.a = (mip.r+mip.g+mip.b)/3.0;
        }
        if (DO_BEZEL == 1.0) {
            //Create a small mipmap to be used to light the bezel corners.
            pixel_out.rgb = textureLod(Source, vTexCoord,lod).rgb + (pixel_out.a*0.5);
        }
        FragColor = pixel_out;
        
    }
}
