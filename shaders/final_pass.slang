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

#define rubyTexture main_pass
#define texture2D(a,b) texture(a,b)

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
    vec3 pixel_out = texture(rubyTexture, vTexCoord).rgb;
    vec3 bloomed;

    //Mix bloom texture
    if (DO_BLOOM > 0.0 ) {
        bloomed=texture(bloom_pass_final, vTexCoord).rgb ;
            
        if ( bloom_on_dark_only  == 1.0) {
           float source_whiteness = (pixel_out.r+pixel_out.g+pixel_out.b)/3;
           float source_darkness = 1-source_whiteness;
           float bloom_mix = DO_BLOOM*source_darkness;
           pixel_out = mix(pixel_out,bloomed,bloom_mix);
        } else {
           pixel_out = mix(pixel_out,bloomed,DO_BLOOM);
        }
    }
    
    //Gamma correction
	vec3 cc = vec3(1.0);
	if  (GAMMA_OUT != 1.0) {
		cc=vec3(GAMMA_OUT);
	}
	pixel_out = pow(pixel_out,cc);


    //Saturation modifier
    if (!(saturation == 1.0)) {
        float l = length(pixel_out);
        pixel_out =  normalize( pow(pixel_out.rgb + vec3(eps), vec3(saturation)))*l  ;
    }
    


    
    //Black frame insertion
    if (DO_ALT_BLANK > 0.0 ) {
        pixel_out = pixel_alternate(pixel_out.rgb, 1 - DO_ALT_BLANK );
    }

    //Out
    FragColor = vec4(pixel_out,0.0);
}
