#include "pows.slang"
#define Pi  (3.14159265358979*2)
#define bloom_directions 8

#define b_offset_x -0.05 //Why is this needed by bloom?

vec3 radial_bloom_std_pow(float Quality, float Directions, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, vTexCoord + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color +=pow(lookup.rgb,fbloom_gamma_vec3);
            steps+=1.0;
        }
    }
    color /= (steps-1);
    return color;
}


vec3 radial_bloom_gamma_1(float Quality, float Directions, float Size) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, vTexCoord + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color += lookup.rgb;
            steps+=1.0;
        }
    }
    color /= (steps-1);
    return color;
}
vec3 radial_bloom_gamma_2(float Quality, float Directions, float Size) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, vTexCoord + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color += (lookup.rgb*lookup.rgb);
            steps+=1.0;
        }
    }
    color /= (steps-1);
    return color;
}
vec3 radial_bloom_gamma_3(float Quality, float Directions, float Size) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, vTexCoord + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color +=pow_3(lookup.rgb);
            steps+=1.0;
        }
    }
    color /= (steps-1);
    return color;
}
vec3 radial_bloom_gamma_4(float Quality, float Directions, float Size) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, vTexCoord + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color +=pow_4(lookup.rgb);
            steps+=1.0;
        }
    }
    color /= (steps-1);
    return color;
}
vec3 radial_bloom_gamma_5(float Quality, float Directions, float Size) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, vTexCoord + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color +=pow_5(lookup.rgb);
            steps+=1.0;
        }
    }
    color /= (steps-1);
    return color;
}
vec3 radial_bloom_gamma_6(float Quality, float Directions, float Size) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, vTexCoord + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color +=pow_6(lookup.rgb);
            steps+=1.0;
        }
    }
    color /= (steps-1);
    return color;
}
vec3 radial_bloom_gamma_7(float Quality, float Directions, float Size) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, vTexCoord + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color +=pow_7(lookup.rgb);
            steps+=1.0;
        }
    }
    color /= (steps-1);
    return color;
}
vec3 radial_bloom_gamma_8(float Quality, float Directions, float Size) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, vTexCoord + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color +=pow_8(lookup.rgb);
            steps+=1.0;
        }
    }
    color /= (steps-1);
    return color;
}
vec3 radial_bloom_gamma_9(float Quality, float Directions, float Size) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, vTexCoord + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color +=pow_9(lookup.rgb);
            steps+=1.0;
        }
    }
    color /= (steps-1);
    return color;
}
vec3 radial_bloom_gamma_10(float Quality, float Directions, float Size) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, vTexCoord + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color +=pow_10(lookup.rgb);
            steps+=1.0;
        }
    }
    color /= (steps-1);
    return color;
}


vec3 bloom(float Directions, float Quality, float Size, float fbloom_gamma) {
    //if (prefer_std_pow != 1.0) {
        if (fbloom_gamma == 1)  { return radial_bloom_gamma_1(Quality, Directions, Size); }
        if (fbloom_gamma == 2)  { return radial_bloom_gamma_2(Quality, Directions, Size); }
        if (fbloom_gamma == 3)  { return radial_bloom_gamma_3(Quality, Directions, Size); }
        if (fbloom_gamma == 4)  { return radial_bloom_gamma_4(Quality, Directions, Size); }
        if (fbloom_gamma == 5)  { return radial_bloom_gamma_5(Quality, Directions, Size); }
        if (fbloom_gamma == 6)  { return radial_bloom_gamma_6(Quality, Directions, Size); }
        if (fbloom_gamma == 7)  { return radial_bloom_gamma_7(Quality, Directions, Size); }
        if (fbloom_gamma == 8)  { return radial_bloom_gamma_8(Quality, Directions, Size); }
        if (fbloom_gamma == 9)  { return radial_bloom_gamma_9(Quality, Directions, Size); }
        if (fbloom_gamma == 10) { return radial_bloom_gamma_10(Quality, Directions, Size);}
    //} else {
        return radial_bloom_std_pow(Quality, Directions, Size, fbloom_gamma);
    //}

}





