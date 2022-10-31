#include "pows.include.slang"
#define Pi2  (3.14159265358979*2)
#define bloom_directions 8

#define b_offset_x -0.05 //Why is this needed by bloom?

#define bdirections 8

vec3 bloom8_std_pow(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float gamma, float r_off, float lod) {

    vec2 passo = dest_size/smpsize.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);

    vec3 lookup = vec3(0.0,0.0,0.0);
    float mystep = 1.0/quality;

    for(float i=mystep; i<=1.0; i+=mystep) {
        color += pow( textureLod(smp, uv + ( passo *i* vec2(-1.0,  r_off )), lod ).rgb, vec3(gamma) );
        color += pow( textureLod(smp, uv + ( passo *i* vec2( 1.0, -r_off )), lod ).rgb, vec3(gamma) );

        color += pow( textureLod(smp, uv + ( passo *i* vec2( r_off, -1.0)), lod ).rgb, vec3(gamma) );
        color += pow( textureLod(smp, uv + ( passo *i* vec2(-r_off, 1.0)), lod ).rgb, vec3(gamma) );

        color += pow( textureLod(smp, uv + ( passo *i* vec2( r_off,   1.0)), lod ).rgb, vec3(gamma) );
        color += pow( textureLod(smp, uv + ( passo *i* vec2(-r_off, -1.0)), lod ).rgb, vec3(gamma) );

        color += pow( textureLod(smp, uv + ( passo *i* vec2(-1.0,  -r_off)), lod ).rgb, vec3(gamma) );
        color += pow( textureLod(smp, uv + ( passo *i* vec2( 1.0,   r_off)), lod ).rgb, vec3(gamma) );
    }
    color /= (quality*8);
    return color;
}


vec3 bloom8_gamma1(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float r_off, float lod) {

    vec2 passo = dest_size/smpsize.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);

    vec3 lookup = vec3(0.0,0.0,0.0);
    float mystep = 1.0/quality;

    for(float i=mystep; i<=1.0; i+=mystep) {
        color += textureLod(smp, uv + ( passo *i* vec2(-1.0,  r_off )), lod ).rgb;
        color += textureLod(smp, uv + ( passo *i* vec2( 1.0, -r_off )), lod ).rgb;

        color += textureLod(smp, uv + ( passo *i* vec2( r_off, -1.0)), lod ).rgb;
        color += textureLod(smp, uv + ( passo *i* vec2(-r_off, 1.0)), lod ).rgb;

        color += textureLod(smp, uv + ( passo *i* vec2( r_off,   1.0)), lod ).rgb;
        color += textureLod(smp, uv + ( passo *i* vec2(-r_off, -1.0)), lod ).rgb;

        color += textureLod(smp, uv + ( passo *i* vec2(-1.0,  -r_off)), lod ).rgb;
        color += textureLod(smp, uv + ( passo *i* vec2( 1.0,   r_off)), lod ).rgb;
    }
    color /= (quality*8);
    return color;
}
vec3 bloom8_gamma2(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float r_off, float lod) {

    vec2 passo = dest_size/smpsize.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);

    vec3 lookup = vec3(0.0,0.0,0.0);
    float mystep = 1.0/quality;

    for(float i=mystep; i<=1.0; i+=mystep) {
        color += pow_2(textureLod(smp, uv + ( passo *i* vec2(-1.0,  r_off )), lod ).rgb);
        color += pow_2(textureLod(smp, uv + ( passo *i* vec2( 1.0, -r_off )), lod ).rgb);

        color += pow_2(textureLod(smp, uv + ( passo *i* vec2( r_off, -1.0)), lod ).rgb);
        color += pow_2(textureLod(smp, uv + ( passo *i* vec2(-r_off, 1.0)), lod ).rgb);

        color += pow_2(textureLod(smp, uv + ( passo *i* vec2( r_off,   1.0)), lod ).rgb);
        color += pow_2(textureLod(smp, uv + ( passo *i* vec2(-r_off, -1.0)), lod ).rgb);

        color += pow_2(textureLod(smp, uv + ( passo *i* vec2(-1.0,  -r_off)), lod ).rgb);
        color += pow_2(textureLod(smp, uv + ( passo *i* vec2( 1.0,   r_off)), lod ).rgb);
    }
    color /= (quality*8);
    return color;
}

vec3 bloom8_gamma3(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float r_off, float lod) {

    vec2 passo = dest_size/smpsize.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);

    vec3 lookup = vec3(0.0,0.0,0.0);
    float mystep = 1.0/quality;

    for(float i=mystep; i<=1.0; i+=mystep) {
        color += pow_3(textureLod(smp, uv + ( passo *i* vec2(-1.0,  r_off )), lod ).rgb);
        color += pow_3(textureLod(smp, uv + ( passo *i* vec2( 1.0, -r_off )), lod ).rgb);

        color += pow_3(textureLod(smp, uv + ( passo *i* vec2( r_off, -1.0)), lod ).rgb);
        color += pow_3(textureLod(smp, uv + ( passo *i* vec2(-r_off, 1.0)), lod ).rgb);

        color += pow_3(textureLod(smp, uv + ( passo *i* vec2( r_off,   1.0)), lod ).rgb);
        color += pow_3(textureLod(smp, uv + ( passo *i* vec2(-r_off, -1.0)), lod ).rgb);

        color += pow_3(textureLod(smp, uv + ( passo *i* vec2(-1.0,  -r_off)), lod ).rgb);
        color += pow_3(textureLod(smp, uv + ( passo *i* vec2( 1.0,   r_off)), lod ).rgb);
    }
    color /= (quality*8);
    return color;
}

vec3 bloom8_gamma4(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float r_off, float lod) {

    vec2 passo = dest_size/smpsize.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);

    vec3 lookup = vec3(0.0,0.0,0.0);
    float mystep = 1.0/quality;

    for(float i=mystep; i<=1.0; i+=mystep) {
        color += pow_4(textureLod(smp, uv + ( passo *i* vec2(-1.0,  r_off )), lod ).rgb);
        color += pow_4(textureLod(smp, uv + ( passo *i* vec2( 1.0, -r_off )), lod ).rgb);

        color += pow_4(textureLod(smp, uv + ( passo *i* vec2( r_off, -1.0)), lod ).rgb);
        color += pow_4(textureLod(smp, uv + ( passo *i* vec2(-r_off, 1.0)), lod ).rgb);

        color += pow_4(textureLod(smp, uv + ( passo *i* vec2( r_off,   1.0)), lod ).rgb);
        color += pow_4(textureLod(smp, uv + ( passo *i* vec2(-r_off, -1.0)), lod ).rgb);

        color += pow_4(textureLod(smp, uv + ( passo *i* vec2(-1.0,  -r_off)), lod ).rgb);
        color += pow_4(textureLod(smp, uv + ( passo *i* vec2( 1.0,   r_off)), lod ).rgb);
    }
    color /= (quality*8);
    return color;
}

vec3 bloom8_gamma5(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float r_off, float lod) {

    vec2 passo = dest_size/smpsize.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);

    vec3 lookup = vec3(0.0,0.0,0.0);
    float mystep = 1.0/quality;

    for(float i=mystep; i<=1.0; i+=mystep) {
        color += pow_5(textureLod(smp, uv + ( passo *i* vec2(-1.0,  r_off )), lod ).rgb);
        color += pow_5(textureLod(smp, uv + ( passo *i* vec2( 1.0, -r_off )), lod ).rgb);

        color += pow_5(textureLod(smp, uv + ( passo *i* vec2( r_off, -1.0)), lod ).rgb);
        color += pow_5(textureLod(smp, uv + ( passo *i* vec2(-r_off, 1.0)), lod ).rgb);

        color += pow_5(textureLod(smp, uv + ( passo *i* vec2( r_off,   1.0)), lod ).rgb);
        color += pow_5(textureLod(smp, uv + ( passo *i* vec2(-r_off, -1.0)), lod ).rgb);

        color += pow_5(textureLod(smp, uv + ( passo *i* vec2(-1.0,  -r_off)), lod ).rgb);
        color += pow_5(textureLod(smp, uv + ( passo *i* vec2( 1.0,   r_off)), lod ).rgb);
    }
    color /= (quality*8);
    return color;
}

vec3 bloom8_gamma6(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float r_off, float lod) {

    vec2 passo = dest_size/smpsize.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);

    vec3 lookup = vec3(0.0,0.0,0.0);
    float mystep = 1.0/quality;

    for(float i=mystep; i<=1.0; i+=mystep) {
        color += pow_6(textureLod(smp, uv + ( passo *i* vec2(-1.0,  r_off )), lod ).rgb);
        color += pow_6(textureLod(smp, uv + ( passo *i* vec2( 1.0, -r_off )), lod ).rgb);

        color += pow_6(textureLod(smp, uv + ( passo *i* vec2( r_off, -1.0)), lod ).rgb);
        color += pow_6(textureLod(smp, uv + ( passo *i* vec2(-r_off, 1.0)), lod ).rgb);

        color += pow_6(textureLod(smp, uv + ( passo *i* vec2( r_off,   1.0)), lod ).rgb);
        color += pow_6(textureLod(smp, uv + ( passo *i* vec2(-r_off, -1.0)), lod ).rgb);

        color += pow_6(textureLod(smp, uv + ( passo *i* vec2(-1.0,  -r_off)), lod ).rgb);
        color += pow_6(textureLod(smp, uv + ( passo *i* vec2( 1.0,   r_off)), lod ).rgb);
    }
    color /= (quality*8);
    return color;
}

vec3 bloom8_gamma7(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float r_off, float lod) {

    vec2 passo = dest_size/smpsize.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);

    vec3 lookup = vec3(0.0,0.0,0.0);
    float mystep = 1.0/quality;

    for(float i=mystep; i<=1.0; i+=mystep) {
        color += pow_7(textureLod(smp, uv + ( passo *i* vec2(-1.0,  r_off )), lod ).rgb);
        color += pow_7(textureLod(smp, uv + ( passo *i* vec2( 1.0, -r_off )), lod ).rgb);

        color += pow_7(textureLod(smp, uv + ( passo *i* vec2( r_off, -1.0)), lod ).rgb);
        color += pow_7(textureLod(smp, uv + ( passo *i* vec2(-r_off, 1.0)), lod ).rgb);

        color += pow_7(textureLod(smp, uv + ( passo *i* vec2( r_off,   1.0)), lod ).rgb);
        color += pow_7(textureLod(smp, uv + ( passo *i* vec2(-r_off, -1.0)), lod ).rgb);

        color += pow_7(textureLod(smp, uv + ( passo *i* vec2(-1.0,  -r_off)), lod ).rgb);
        color += pow_7(textureLod(smp, uv + ( passo *i* vec2( 1.0,   r_off)), lod ).rgb);
    }
    color /= (quality*8);
    return color;
}

vec3 bloom8_gamma8(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float r_off, float lod) {

    vec2 passo = dest_size/smpsize.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);

    vec3 lookup = vec3(0.0,0.0,0.0);
    float mystep = 1.0/quality;

    for(float i=mystep; i<=1.0; i+=mystep) {
        color += pow_8(textureLod(smp, uv + ( passo *i* vec2(-1.0,  r_off )), lod ).rgb);
        color += pow_8(textureLod(smp, uv + ( passo *i* vec2( 1.0, -r_off )), lod ).rgb);

        color += pow_8(textureLod(smp, uv + ( passo *i* vec2( r_off, -1.0)), lod ).rgb);
        color += pow_8(textureLod(smp, uv + ( passo *i* vec2(-r_off, 1.0)), lod ).rgb);

        color += pow_8(textureLod(smp, uv + ( passo *i* vec2( r_off,   1.0)), lod ).rgb);
        color += pow_8(textureLod(smp, uv + ( passo *i* vec2(-r_off, -1.0)), lod ).rgb);

        color += pow_8(textureLod(smp, uv + ( passo *i* vec2(-1.0,  -r_off)), lod ).rgb);
        color += pow_8(textureLod(smp, uv + ( passo *i* vec2( 1.0,   r_off)), lod ).rgb);
    }
    color /= (quality*8);
    return color;
}

vec3 bloom8_gamma9(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float r_off, float lod) {

    vec2 passo = dest_size/smpsize.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);

    vec3 lookup = vec3(0.0,0.0,0.0);
    float mystep = 1.0/quality;

    for(float i=mystep; i<=1.0; i+=mystep) {
        color += pow_9(textureLod(smp, uv + ( passo *i* vec2(-1.0,  r_off )), lod ).rgb);
        color += pow_9(textureLod(smp, uv + ( passo *i* vec2( 1.0, -r_off )), lod ).rgb);

        color += pow_9(textureLod(smp, uv + ( passo *i* vec2( r_off, -1.0)), lod ).rgb);
        color += pow_9(textureLod(smp, uv + ( passo *i* vec2(-r_off, 1.0)), lod ).rgb);

        color += pow_9(textureLod(smp, uv + ( passo *i* vec2( r_off,   1.0)), lod ).rgb);
        color += pow_9(textureLod(smp, uv + ( passo *i* vec2(-r_off, -1.0)), lod ).rgb);

        color += pow_9(textureLod(smp, uv + ( passo *i* vec2(-1.0,  -r_off)), lod ).rgb);
        color += pow_9(textureLod(smp, uv + ( passo *i* vec2( 1.0,   r_off)), lod ).rgb);
    }
    color /= (quality*8);
    return color;
}

vec3 bloom8_gamma10(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float r_off, float lod) {

    vec2 passo = dest_size/smpsize.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);

    vec3 lookup = vec3(0.0,0.0,0.0);
    float mystep = 1.0/quality;

    for(float i=mystep; i<=1.0; i+=mystep) {
        color += pow_10(textureLod(smp, uv + ( passo *i* vec2(-1.0,  r_off )), lod ).rgb);
        color += pow_10(textureLod(smp, uv + ( passo *i* vec2( 1.0, -r_off )), lod ).rgb);

        color += pow_10(textureLod(smp, uv + ( passo *i* vec2( r_off, -1.0)), lod ).rgb);
        color += pow_10(textureLod(smp, uv + ( passo *i* vec2(-r_off, 1.0)), lod ).rgb);

        color += pow_10(textureLod(smp, uv + ( passo *i* vec2( r_off,   1.0)), lod ).rgb);
        color += pow_10(textureLod(smp, uv + ( passo *i* vec2(-r_off, -1.0)), lod ).rgb);

        color += pow_10(textureLod(smp, uv + ( passo *i* vec2(-1.0,  -r_off)), lod ).rgb);
        color += pow_10(textureLod(smp, uv + ( passo *i* vec2( 1.0,   r_off)), lod ).rgb);
    }
    color /= (quality*8);
    return color;
}


vec3 bloom(sampler2D smp, vec2 uv, vec4 smpsize, vec2 dest_size, float quality, float gamma, float r_off, float lod) {
        if (gamma == 1) return bloom8_gamma1(smp, uv, smpsize, dest_size, quality, r_off, lod);
        if (gamma == 2) return bloom8_gamma2(smp, uv, smpsize, dest_size, quality, r_off, lod);
        if (gamma == 3) return bloom8_gamma3(smp, uv, smpsize, dest_size, quality, r_off, lod);
        if (gamma == 4) return bloom8_gamma4(smp, uv, smpsize, dest_size, quality, r_off, lod);
        if (gamma == 5) return bloom8_gamma5(smp, uv, smpsize, dest_size, quality, r_off, lod);
        if (gamma == 6) return bloom8_gamma6(smp, uv, smpsize, dest_size, quality, r_off, lod);
        if (gamma == 7) return bloom8_gamma7(smp, uv, smpsize, dest_size, quality, r_off, lod);
        if (gamma == 8) return bloom8_gamma8(smp, uv, smpsize, dest_size, quality, r_off, lod);
        if (gamma == 9) return bloom8_gamma9(smp, uv, smpsize, dest_size, quality, r_off, lod);
        if (gamma == 10) return bloom8_gamma10(smp, uv, smpsize, dest_size, quality, r_off, lod);
        return bloom8_std_pow(smp, uv, smpsize, dest_size, quality, gamma, r_off, lod);
}
