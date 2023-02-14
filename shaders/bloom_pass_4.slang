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
layout(set = 0, binding = 1) uniform sampler2D Source;
layout(set = 0, binding = 2) uniform sampler2D avglum_pass;



#include "includes/functions.include.slang"
#include "includes/blooms.include.slang"

#define offset 0.5890486225480862 // TAU/8.0/4.0*3.0

//The curve shoulder to map scene luminance to bloom mix strength
#define BLOOM_EXPOSURE_CURVE_SHOULDER 0.33

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
    bloomed = pixel_push_luminance(bloomed, BLOOM_POWER);
    
    float fbloom_mix = BLOOM_MIX;
    if (BLOOM_BYPASS == 0.0 || BLOOM_BYPASS == 2.0) {
        float over_white_correction = 1.0;
        if (BLOOM_OVER_WHITE < 1.0) {
            //Use mipmap available in avglum_pass to identify bright areas.
            vec3 avglum = texture(avglum_pass,vTexCoord).rgb;
            float b_brightness = max(avglum.b,max(avglum.r,avglum.g));
            b_brightness *= 1-BLOOM_OVER_WHITE;
            over_white_correction =1- b_brightness;
        }
        
        
        bloomed*=BLOOM_POWER;
        
        // Modulate exposure
        // Branching with (if BLOOM_ADPT == 0.0) does not gain anything.
        float smoothed_avglum = texture(avglum_pass, vec2(0.75)).a * BLOOM_ADPT; 
        float bloom_mix_adapted = max(0.0, BLOOM_MIX - smoothed_avglum);
                
        if (BLOOM_BYPASS == 2.0) fbloom_mix = 1.0;
        bloom_mix_adapted = fbloom_mix * ( 1- pow(smoothed_avglum, BLOOM_EXPOSURE_CURVE_SHOULDER -smoothed_avglum * BLOOM_EXPOSURE_CURVE_SHOULDER) );
        
        bloomed = bloomed * bloom_mix_adapted * over_white_correction ;
    }
    
      
    FragColor = vec4(bloomed, 1.0); //FragColor = texture(Source,vTexCoord);

}
