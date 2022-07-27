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
layout(set = 0, binding = 2) uniform sampler2D main_pass;
layout(set = 0, binding = 4) uniform sampler2D bloom_pass_final;

vec3 pixel_alternate(vec3 source, float darkness) {
    float line = vTexCoord.y * params.OutputSize.y;
    vec3 pixel_out = source;
    if  (int(mod(float(params.FrameCount),2.0  )) == 1) {
        if  (int(mod(line,2.0  )) == 1) {
            pixel_out=mix(vec3(0),source,darkness) ;
        }
    } else {
        if  (int(mod(line,2.0  )) == 0) {
            pixel_out=mix(vec3(0),source,darkness) ;
        }
    }
    return pixel_out;
}


void main(void) {
    vec3 pixel_out = texture(main_pass, vTexCoord).rgb;
    vec3 bloomed;

    //Mix bloom texture
    if (DO_BLOOM == 1.0 ) {
        bloomed=texture(bloom_pass_final, vTexCoord).rgb ;
            
        if ( bloom_on_dark_only  == 1.0) {
           float source_whiteness = (pixel_out.r+pixel_out.g+pixel_out.b)/3;
           float source_darkness = 1-source_whiteness;
           float local_bloom_mix = BLOOM_MIX*source_darkness;
           pixel_out = mix(pixel_out,bloomed,local_bloom_mix);
        } else {
           pixel_out = mix(pixel_out,bloomed,BLOOM_MIX);
        }
    }


    //Black frame insertion
    if (DO_ALT_BLANK == 1.0 ) {
        pixel_out = pixel_alternate(pixel_out.rgb, 1 - ALT_BLANK_STRENGTH );
    }

    //Out
    FragColor = vec4(pixel_out,0.0);
}
