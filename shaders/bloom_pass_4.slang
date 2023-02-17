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
layout(set = 0, binding = 3) uniform sampler2D first_pass;
layout(set = 0, binding = 4) uniform sampler2D bloom_pass_finalFeedback;


#include "includes/functions.include.slang"
#include "includes/blooms.include.slang"

#define offset 0.5890486225480862 // TAU/8.0/4.0*3.0

//The curve shoulder to map scene luminance to bloom mix strength
#define BLOOM_EXPOSURE_CURVE_SHOULDER 0.33

//How much times (sqrt) is the zone that will motulate the bloom mix
//smaller than the area? read: the lod, use pot
#define BLOOM_LUM_ZONE_W 7

#define BLOOM_PUPIL_ADAPTION_SPEED 0.1

float get_avg_lum_from_mip(sampler2D tex, vec2 co, float lod) {
    vec3 mip = textureLod(first_pass, co, lod).rgb;
    mip = apply_fuzzy_main_pass(mip);
    //return (mip.r+mip.g+mip.b)/3.0;
    float luminance = rgb_to_gray(mip);
    //temporal smooth.
    //the defined emulated eye adaption speed needs to be divided 
    //by the eye adaption strength (BLOOM_EYE_ADPT_SRT)
    float eye_adaption_speed = (BLOOM_PUPIL_ADAPTION_SPEED / BLOOM_EYE_ADPT_SRT);
    eye_adaption_speed = clamp(BLOOM_PUPIL_ADAPTION_SPEED, 0.01, 1.0);
    luminance = mix(texture(bloom_pass_finalFeedback,vTexCoord).a, luminance, eye_adaption_speed);
    return luminance + eps;
}



void main() {
    if (DO_BLOOM == 0.0) return;

    
    //Smooth luminance with specified lod in this alpha channel
    float zone_luminance = get_avg_lum_from_mip(first_pass, vTexCoord, BLOOM_LUM_ZONE_W);
    
    
      
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
        
        // Modulate exposure over time too.
        // Branching with (if BLOOM_EYE_ADPT_SRT == 0.0) does not gain anything.
        float smoothed_avglum = zone_luminance * BLOOM_EYE_ADPT_SRT;
        float bloom_mix_adapted = max(0.0, BLOOM_MIX - smoothed_avglum);
        
        
        if (BLOOM_BYPASS == 2.0) fbloom_mix = 1.0;
        
        
        float pow_exp = BLOOM_EXPOSURE_CURVE_SHOULDER - smoothed_avglum * BLOOM_EXPOSURE_CURVE_SHOULDER;
        pow_exp = max(0.0, pow_exp); //avoid negative exps.
        bloom_mix_adapted = fbloom_mix * ( 1- pow(smoothed_avglum, pow_exp) );
        
        bloomed = bloomed * bloom_mix_adapted * over_white_correction ;
    }
    
    FragColor = vec4(bloomed, zone_luminance);   
    
    //FragColor = vec4(zone_luminance); //Use me to see luminosity zones
    
}
