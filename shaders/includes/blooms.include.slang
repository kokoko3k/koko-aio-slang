#include "pows.include.slang"
#define Pi2 6.283
#define bloom_directions 8

#define b_offset_x -0.05 //Why is this needed by bloom?

#define bdirections 8

vec3 bloom_std_pow(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float gamma, float start_offset, float lod) {
    vec2 r = dest_size/smpsize.xy ;
    vec3 lookup;
    vec3 color  = vec3(0.0,0.0,0.0);
    float steps=0.0;

    for( float d=start_offset; d<Pi2; d+=Pi2/bdirections) {
        for(float i=1.0/quality; i<=1.0; i+=1.0/quality) {
            lookup = textureLod(smp, uv + vec2( cos(d), sin(d)) * r * i, lod ).rgb ;
            color +=pow(lookup.rgb,vec3(gamma));
        }
    }
    color /= (quality*bdirections);
    return color;
}


vec3 bloom_gamma1(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float start_offset, float lod) {
    vec2 r = dest_size/smpsize.xy ;
    vec3 lookup;
    vec3 color  = vec3(0.0,0.0,0.0);
    float steps=0.0;

    for( float d=start_offset; d<Pi2; d+=Pi2/bdirections) {
        for(float i=1.0/quality; i<=1.0; i+=1.0/quality) {
            lookup = textureLod(smp, uv + vec2( cos(d), sin(d)) * r * i, lod ).rgb ;
            color +=lookup.rgb;
        }
    }
    color /= (quality*bdirections);
    return color;
}
vec3 bloom_gamma2(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float start_offset, float lod) {
    vec2 r = dest_size/smpsize.xy ;
    vec3 lookup;
    vec3 color  = vec3(0.0,0.0,0.0);
    float steps=0.0;

    for( float d=start_offset; d<Pi2; d+=Pi2/bdirections) {
        for(float i=1.0/quality; i<=1.0; i+=1.0/quality) {
            lookup = textureLod(smp, uv + vec2( cos(d), sin(d)) * r * i, lod ).rgb ;
            color +=lookup.rgb * lookup.rgb;
        }
    }
    color /= (quality*bdirections);
    return color;
}

vec3 bloom_gamma3(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float start_offset, float lod) {
    vec2 r = dest_size/smpsize.xy ;
    vec3 lookup;
    vec3 color  = vec3(0.0,0.0,0.0);
    float steps=0.0;

    for( float d=start_offset; d<Pi2; d+=Pi2/bdirections) {
        for(float i=1.0/quality; i<=1.0; i+=1.0/quality) {
            lookup = textureLod(smp, uv + vec2( cos(d), sin(d)) * r * i, lod ).rgb ;
            color +=pow_3(lookup.rgb);
        }
    }
    color /= (quality*bdirections);
    return color;
}

vec3 bloom_gamma4(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float start_offset, float lod) {
    vec2 r = dest_size/smpsize.xy ;
    vec3 lookup;
    vec3 color  = vec3(0.0,0.0,0.0);
    float steps=0.0;

    for( float d=start_offset; d<Pi2; d+=Pi2/bdirections) {
        for(float i=1.0/quality; i<=1.0; i+=1.0/quality) {
            lookup = textureLod(smp, uv + vec2( cos(d), sin(d)) * r * i, lod ).rgb ;
            color +=pow_4(lookup.rgb);
        }
    }
    color /= (quality*bdirections);
    return color;
}

vec3 bloom_gamma5(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float start_offset, float lod) {
    vec2 r = dest_size/smpsize.xy ;
    vec3 lookup;
    vec3 color  = vec3(0.0,0.0,0.0);
    float steps=0.0;

    for( float d=start_offset; d<Pi2; d+=Pi2/bdirections) {
        for(float i=1.0/quality; i<=1.0; i+=1.0/quality) {
            lookup = textureLod(smp, uv + vec2( cos(d), sin(d)) * r * i, lod ).rgb ;
            color +=pow_5(lookup.rgb);
        }
    }
    color /= (quality*bdirections);
    return color;
}

vec3 bloom_gamma6(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float start_offset, float lod) {
    vec2 r = dest_size/smpsize.xy ;
    vec3 lookup;
    vec3 color  = vec3(0.0,0.0,0.0);
    float steps=0.0;

    for( float d=start_offset; d<Pi2; d+=Pi2/bdirections) {
        for(float i=1.0/quality; i<=1.0; i+=1.0/quality) {
            lookup = textureLod(smp, uv + vec2( cos(d), sin(d)) * r * i, lod ).rgb ;
            color +=pow_6(lookup.rgb);
        }
    }
    color /= (quality*bdirections);
    return color;
}

vec3 bloom_gamma7(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float start_offset, float lod) {
    vec2 r = dest_size/smpsize.xy ;
    vec3 lookup;
    vec3 color  = vec3(0.0,0.0,0.0);
    float steps=0.0;

    for( float d=start_offset; d<Pi2; d+=Pi2/bdirections) {
        for(float i=1.0/quality; i<=1.0; i+=1.0/quality) {
            lookup = textureLod(smp, uv + vec2( cos(d), sin(d)) * r * i, lod ).rgb ;
            color +=pow_7(lookup.rgb);
        }
    }
    color /= (quality*bdirections);
    return color;
}

vec3 bloom_gamma8(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float start_offset, float lod) {
    vec2 r = dest_size/smpsize.xy ;
    vec3 lookup;
    vec3 color  = vec3(0.0,0.0,0.0);
    float steps=0.0;

    for( float d=start_offset; d<Pi2; d+=Pi2/bdirections) {
        for(float i=1.0/quality; i<=1.0; i+=1.0/quality) {
            lookup = textureLod(smp, uv + vec2( cos(d), sin(d)) * r * i, lod ).rgb ;
            color +=pow_8(lookup.rgb);
        }
    }
    color /= (quality*bdirections);
    return color;
}

vec3 bloom_gamma9(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float start_offset, float lod) {
    vec2 r = dest_size/smpsize.xy ;
    vec3 lookup;
    vec3 color  = vec3(0.0,0.0,0.0);
    float steps=0.0;

    for( float d=start_offset; d<Pi2; d+=Pi2/bdirections) {
        for(float i=1.0/quality; i<=1.0; i+=1.0/quality) {
            lookup = textureLod(smp, uv + vec2( cos(d), sin(d)) * r * i, lod ).rgb ;
            color +=pow_9(lookup.rgb);
        }
    }
    color /= (quality*bdirections);
    return color;
}

vec3 bloom_gamma10(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float start_offset, float lod) {
    vec2 r = dest_size/smpsize.xy ;
    vec3 lookup;
    vec3 color  = vec3(0.0,0.0,0.0);
    float steps=0.0;

    for( float d=start_offset; d<Pi2; d+=Pi2/bdirections) {
        for(float i=1.0/quality; i<=1.0; i+=1.0/quality) {
            lookup = textureLod(smp, uv + vec2( cos(d), sin(d)) * r * i, lod ).rgb ;
            color +=pow_10(lookup.rgb);
        }
    }
    color /= (quality*bdirections);
    return color;
}


vec3 bloom(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float gamma, float start_offset, float lod) {
        if (gamma == 1) return bloom_gamma1(smp, uv, smpsize, dest_size, quality, start_offset, lod);
        if (gamma == 2) return bloom_gamma2(smp, uv, smpsize, dest_size, quality, start_offset, lod);
        if (gamma == 3) return bloom_gamma3(smp, uv, smpsize, dest_size, quality, start_offset, lod);
        if (gamma == 4) return bloom_gamma4(smp, uv, smpsize, dest_size, quality, start_offset, lod);
        if (gamma == 5) return bloom_gamma5(smp, uv, smpsize, dest_size, quality, start_offset, lod);
        if (gamma == 6) return bloom_gamma6(smp, uv, smpsize, dest_size, quality, start_offset, lod);
        if (gamma == 7) return bloom_gamma7(smp, uv, smpsize, dest_size, quality, start_offset, lod);
        if (gamma == 8) return bloom_gamma8(smp, uv, smpsize, dest_size, quality, start_offset, lod);
        if (gamma == 9) return bloom_gamma9(smp, uv, smpsize, dest_size, quality, start_offset, lod);
        if (gamma == 10) return bloom_gamma10(smp, uv, smpsize, dest_size, quality, start_offset, lod);
                         return bloom_std_pow(smp, uv, smpsize, dest_size, quality, gamma, start_offset, lod);
}
