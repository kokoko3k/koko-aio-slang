#version 450

// This is one of several passes needed to cheaply emulate the bloom effect.

#include "config.inc"
#include "includes/functions.include.slang"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vFuzzy_main_pass_stage_1;

void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = TexCoord;

    //Get fuzzy mul and pow factor
        vFuzzy_main_pass_stage_1 = apply_fuzzy_main_pass_stage_1();
}

#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vFuzzy_main_pass_stage_1;

layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 1) uniform sampler2D colortools_and_ntsc_pass;

//#include "includes/functions.include.slang"
#include "includes/blooms.include.slang"

bool is_alone(sampler2D smp_mip, vec3 point_nomip,  vec2 co) {
    float nomip_lum = point_nomip.r;
    
    vec2 d = params.OriginalSize.zw * 1.0;
    
    if (nomip_lum < 0.2) return false;
    
    float t=SERVICE1*0.1;
    
    if (texture(smp_mip, co + d * vec2(-1,-1)).r > t) return false;
    if (texture(smp_mip, co + d * vec2(-1,-0)).r > t) return false;
    if (texture(smp_mip, co + d * vec2(-1,+1)).r > t) return false;

    if (texture(smp_mip, co + d * vec2(0,-1)).r > t) return false;
    //if (texture(smp_mip, co + d * vec2(0,-0)).r > t) return false;
    if (texture(smp_mip, co + d * vec2(0,+1)).r > t) return false;

    if (texture(smp_mip, co + d * vec2(1,-1)).r > t) return false;
    if (texture(smp_mip, co + d * vec2(1,-0)).r > t) return false;
    if (texture(smp_mip, co + d * vec2(1,+1)).r > t) return false;    
    
    
    return true;;
    
/*    float lod = 2.0;
    float mipmap1_lum = textureLod(smp_mip, co, 1.0).r;
    float mipmap2_lum = textureLod(smp_mip, co, 2.0).r;
    float mipmap3_lum = textureLod(smp_mip, co, 3.0).r;
    
    
    float mipmap1_shift_lum = textureLod(smp_mip, co, 2.0).r;
    
    float nomip_lum = point_nomip.r;
    
    
    if ( nomip_lum > 0.20 &&
         mip_near_is_dark &&
         mipmap1_lum < SERVICE1

        
        
    )
        return true;
    else
        return false;
    
//     if ( nomip_lum > 0.20 &&
//          mipmap1_lum > mipmap2_lum && 
//          mipmap1_lum < SERVICE1)
//         return true;
//     else
//         return false;
    
//     if ( nomip_lum > 0.35 && mipmap1_lum < SERVICE1)
//         return true;
//     else
//         return false;
  
    
    */
}

vec3 bloom_gamma_power2(sampler2D smp, vec2 uv, vec4 smpsize, vec2 bsize, float quality, float gamma, float power, float start_offset, float lod, sampler2D alone_smp) {
    vec2 r = radius_blur_adapt(bsize) ;
    vec3 lookup;
    vec3 color  = vec3(0.0);
    vec3 vec3gamma = vec3(gamma);

    for( float d=start_offset; d<TAU; d+=TAU/bdirections) {
        for(float i=1.0/quality; i<=1.0; i+=1.0/quality) {
            vec2 co =  uv + vec2( cos(d), sin(d)) * r * i;
            lookup = textureLod(smp, co, lod ).rgb ;
        
/*            if (is_alone(alone_smp, lookup, co))
                lookup = vec3(999.0);
                
            else
                lookup /= 5.0;
*/
            float mip_lum = textureLod(alone_smp, co, 1.0).r;
            if (mip_lum.r < SERVICE1 && mip_lum.r > 0.2)
                lookup = vec3(1-mip_lum);

            color +=pow(lookup.rgb, vec3gamma);
        }
    }
    color /= (quality*bdirections);
    return color * power;
}

void main() {
    if (DO_BLOOM == 0.0) return;
    
    vec3 bloomed = bloom_gamma_power2(
        colortools_and_ntsc_pass,
        vTexCoord,
        params.OriginalSize,
        vec2(BLOOM_SIZE),
        BLOOM_QUALITY,
        BLOOM_GAMMA, 1.0,
        0.0,
        0.0,
        colortools_and_ntsc_pass
    );
    bloomed = apply_fuzzy_main_pass_stage_2(bloomed, vFuzzy_main_pass_stage_1);
    FragColor.rgb = bloomed;
}
