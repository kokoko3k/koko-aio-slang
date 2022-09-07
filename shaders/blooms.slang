#include "pows.slang"
#define Pi  (3.14159265358979*2)
#define bloom_directions 8

#define b_offset_x -0.05 //Why is this needed by bloom?

vec3 radial_bloom_std_pow(float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;
    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup ;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);  
    vec2 fstep;
    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
        fstep = Radius * i;
            lookup = texture(SourceTexture, vTexCoord + vec2( fstep.x , 0.0     ) ).rgb;  //left
            color +=pow(lookup.rgb,fbloom_gamma_vec3);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , 0.0     ) ).rgb;  //right
            color +=pow(lookup.rgb,fbloom_gamma_vec3);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , fstep.y ) ).rgb;  //up
            color +=pow(lookup.rgb,fbloom_gamma_vec3);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , -fstep.y) ).rgb;  //down
            color +=pow(lookup.rgb,fbloom_gamma_vec3);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , fstep.y ) ).rgb;  //upright
            color +=pow(lookup.rgb,fbloom_gamma_vec3);
            lookup = texture(SourceTexture, vTexCoord + vec2(fstep.x  , -fstep.y) ).rgb;  //downleft
            color +=pow(lookup.rgb,fbloom_gamma_vec3);
            lookup = texture(SourceTexture, vTexCoord + fstep).rgb;  //upleft
            color +=pow(lookup.rgb,fbloom_gamma_vec3);
            lookup = texture(SourceTexture, vTexCoord - fstep).rgb; //downright  
            color +=pow(lookup.rgb,fbloom_gamma_vec3);
    }
    color = color / (Quality * 8.0);
    return color;
}

vec3 radial_bloom_gamma_1(float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;
    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup ;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);  
    vec2 fstep;
    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
        fstep = Radius * i;
            lookup = texture(SourceTexture, vTexCoord + vec2( fstep.x , 0.0     ) ).rgb;  //left
            color += lookup.rgb;
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , 0.0     ) ).rgb;  //right
            color += lookup.rgb;
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , fstep.y ) ).rgb;  //up
            color += lookup.rgb;
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , -fstep.y) ).rgb;  //down
            color += lookup.rgb;
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , fstep.y ) ).rgb;  //upright
            color += lookup.rgb;
            lookup = texture(SourceTexture, vTexCoord + vec2(fstep.x  , -fstep.y) ).rgb;  //downleft
            color += lookup.rgb;
            lookup = texture(SourceTexture, vTexCoord + fstep).rgb;  //upleft
            color += lookup.rgb;
            lookup = texture(SourceTexture, vTexCoord - fstep).rgb; //downright  
            color += lookup.rgb;
    }
    color = color / (Quality * 8.0);
    return color;
}


vec3 radial_bloom_gamma_2(float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;
    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup ;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);  
    vec2 fstep;
    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
        fstep = Radius * i;
            lookup = texture(SourceTexture, vTexCoord + vec2( fstep.x , 0.0     ) ).rgb;  //left
            color += lookup.rgb * lookup.rgb ;
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , 0.0     ) ).rgb;  //right
            color += lookup.rgb * lookup.rgb ;
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , fstep.y ) ).rgb;  //up
            color += lookup.rgb * lookup.rgb ;
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , -fstep.y) ).rgb;  //down
            color += lookup.rgb * lookup.rgb ;
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , fstep.y ) ).rgb;  //upright
            color += lookup.rgb * lookup.rgb ;
            lookup = texture(SourceTexture, vTexCoord + vec2(fstep.x  , -fstep.y) ).rgb;  //downleft
            color += lookup.rgb * lookup.rgb ;
            lookup = texture(SourceTexture, vTexCoord + fstep).rgb;  //upleft
            color += lookup.rgb * lookup.rgb ;
            lookup = texture(SourceTexture, vTexCoord - fstep).rgb; //downright  
            color += lookup.rgb * lookup.rgb ;
    }
    color = color / (Quality * 8.0);
    return color;
}

vec3 radial_bloom_gamma_3(float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;
    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup ;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);  
    vec2 fstep;
    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
        fstep = Radius * i;
            lookup = texture(SourceTexture, vTexCoord + vec2( fstep.x , 0.0     ) ).rgb;  //left
            color += pow_3(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , 0.0     ) ).rgb;  //right
            color += pow_3(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , fstep.y ) ).rgb;  //up
            color += pow_3(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , -fstep.y) ).rgb;  //down
            color += pow_3(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , fstep.y ) ).rgb;  //upright
            color += pow_3(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(fstep.x  , -fstep.y) ).rgb;  //downleft
            color += pow_3(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + fstep).rgb;  //upleft
            color += pow_3(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord - fstep).rgb; //downright  
            color += pow_3(lookup.rgb);
    }
    color = color / (Quality * 8.0);
    return color;
}

vec3 radial_bloom_gamma_4(float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;
    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup ;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);  
    vec2 fstep;
    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
        fstep = Radius * i;
            lookup = texture(SourceTexture, vTexCoord + vec2( fstep.x , 0.0     ) ).rgb;  //left
            color += pow_4(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , 0.0     ) ).rgb;  //right
            color += pow_4(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , fstep.y ) ).rgb;  //up
            color += pow_4(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , -fstep.y) ).rgb;  //down
            color += pow_4(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , fstep.y ) ).rgb;  //upright
            color += pow_4(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(fstep.x  , -fstep.y) ).rgb;  //downleft
            color += pow_4(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + fstep).rgb;  //upleft
            color += pow_4(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord - fstep).rgb; //downright  
            color += pow_4(lookup.rgb);
    }
    color = color / (Quality * 8.0);
    return color;
}

vec3 radial_bloom_gamma_5(float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;
    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup ;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);  
    vec2 fstep;
    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
        fstep = Radius * i;
            lookup = texture(SourceTexture, vTexCoord + vec2( fstep.x , 0.0     ) ).rgb;  //left
            color += pow_5(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , 0.0     ) ).rgb;  //right
            color += pow_5(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , fstep.y ) ).rgb;  //up
            color += pow_5(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , -fstep.y) ).rgb;  //down
            color += pow_5(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , fstep.y ) ).rgb;  //upright
            color += pow_5(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(fstep.x  , -fstep.y) ).rgb;  //downleft
            color += pow_5(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + fstep).rgb;  //upleft
            color += pow_5(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord - fstep).rgb; //downright  
            color += pow_5(lookup.rgb);
    }
    color = color / (Quality * 8.0);
    return color;
}

vec3 radial_bloom_gamma_6(float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;
    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup ;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);  
    vec2 fstep;
    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
        fstep = Radius * i;
            lookup = texture(SourceTexture, vTexCoord + vec2( fstep.x , 0.0     ) ).rgb;  //left
            color += pow_6(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , 0.0     ) ).rgb;  //right
            color += pow_6(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , fstep.y ) ).rgb;  //up
            color += pow_6(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , -fstep.y) ).rgb;  //down
            color += pow_6(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , fstep.y ) ).rgb;  //upright
            color += pow_6(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(fstep.x  , -fstep.y) ).rgb;  //downleft
            color += pow_6(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + fstep).rgb;  //upleft
            color += pow_6(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord - fstep).rgb; //downright  
            color += pow_6(lookup.rgb);
    }
    color = color / (Quality * 8.0);
    return color;
}

vec3 radial_bloom_gamma_7(float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;
    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup ;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);  
    vec2 fstep;
    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
        fstep = Radius * i;
            lookup = texture(SourceTexture, vTexCoord + vec2( fstep.x , 0.0     ) ).rgb;  //left
            color += pow_7(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , 0.0     ) ).rgb;  //right
            color += pow_7(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , fstep.y ) ).rgb;  //up
            color += pow_7(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , -fstep.y) ).rgb;  //down
            color += pow_7(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , fstep.y ) ).rgb;  //upright
            color += pow_7(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(fstep.x  , -fstep.y) ).rgb;  //downleft
            color += pow_7(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + fstep).rgb;  //upleft
            color += pow_7(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord - fstep).rgb; //downright  
            color += pow_7(lookup.rgb);
    }
    color = color / (Quality * 8.0);
    return color;
}

vec3 radial_bloom_gamma_8(float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;
    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup ;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);  
    vec2 fstep;
    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
        fstep = Radius * i;
            lookup = texture(SourceTexture, vTexCoord + vec2( fstep.x , 0.0     ) ).rgb;  //left
            color += pow_8(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , 0.0     ) ).rgb;  //right
            color += pow_8(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , fstep.y ) ).rgb;  //up
            color += pow_8(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , -fstep.y) ).rgb;  //down
            color += pow_8(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , fstep.y ) ).rgb;  //upright
            color += pow_8(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(fstep.x  , -fstep.y) ).rgb;  //downleft
            color += pow_8(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + fstep).rgb;  //upleft
            color += pow_8(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord - fstep).rgb; //downright  
            color += pow_8(lookup.rgb);
    }
    color = color / (Quality * 8.0);
    return color;
}

vec3 radial_bloom_gamma_9(float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;
    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup ;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);  
    vec2 fstep;
    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
        fstep = Radius * i;
            lookup = texture(SourceTexture, vTexCoord + vec2( fstep.x , 0.0     ) ).rgb;  //left
            color += pow_9(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , 0.0     ) ).rgb;  //right
            color += pow_9(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , fstep.y ) ).rgb;  //up
            color += pow_9(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , -fstep.y) ).rgb;  //down
            color += pow_9(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , fstep.y ) ).rgb;  //upright
            color += pow_9(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(fstep.x  , -fstep.y) ).rgb;  //downleft
            color += pow_9(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + fstep).rgb;  //upleft
            color += pow_9(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord - fstep).rgb; //downright  
            color += pow_9(lookup.rgb);
    }
    color = color / (Quality * 8.0);
    return color;
}

vec3 radial_bloom_gamma_10(float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;
    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup ;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);  
    vec2 fstep;
    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
        fstep = Radius * i;
            lookup = texture(SourceTexture, vTexCoord + vec2( fstep.x , 0.0     ) ).rgb;  //left
            color += pow_10(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , 0.0     ) ).rgb;  //right
            color += pow_10(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , fstep.y ) ).rgb;  //up
            color += pow_10(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2( 0.0     , -fstep.y) ).rgb;  //down
            color += pow_10(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(-fstep.x , fstep.y ) ).rgb;  //upright
            color += pow_10(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + vec2(fstep.x  , -fstep.y) ).rgb;  //downleft
            color += pow_10(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord + fstep).rgb;  //upleft
            color += pow_10(lookup.rgb);
            lookup = texture(SourceTexture, vTexCoord - fstep).rgb; //downright  
            color += pow_10(lookup.rgb);
    }
    color = color / (Quality * 8.0);
    return color;
}

vec3 bloom(float Quality, float Size, float fbloom_gamma)  {
        if (fbloom_gamma == 1) return radial_bloom_gamma_1(Quality, Size, fbloom_gamma);
        if (fbloom_gamma == 2) return radial_bloom_gamma_2(Quality, Size, fbloom_gamma);
        if (fbloom_gamma == 3) return radial_bloom_gamma_3(Quality, Size, fbloom_gamma);
        if (fbloom_gamma == 4) return radial_bloom_gamma_4(Quality, Size, fbloom_gamma);
        if (fbloom_gamma == 5) return radial_bloom_gamma_5(Quality, Size, fbloom_gamma);
        if (fbloom_gamma == 6) return radial_bloom_gamma_6(Quality, Size, fbloom_gamma);
        if (fbloom_gamma == 7) return radial_bloom_gamma_7(Quality, Size, fbloom_gamma);
        if (fbloom_gamma == 8) return radial_bloom_gamma_8(Quality, Size, fbloom_gamma);
        if (fbloom_gamma == 9) return radial_bloom_gamma_9(Quality, Size, fbloom_gamma);
        if (fbloom_gamma == 10) return radial_bloom_gamma_10(Quality, Size, fbloom_gamma);
        return radial_bloom_std_pow(Quality, Size, fbloom_gamma);
}





