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
layout(set = 0, binding = 2) uniform sampler2D Original;


vec3 pow3(vec3 v, float fpow) {
     
    //Depending on the hardware and shader compiler (and maybe on the exponent)
    //one may prefer to use the default pow or the integer optimized one.
    if (prefer_std_pow == 1) {
        return pow(v,vec3(fpow));
    }
    
    vec3 v2,v4;
    if (fpow == 1) {
        return v;
    } else if (fpow == 2) {
        return v*v;
        
    } else if (fpow == 3) {
        return v*v*v;
        
    } else if (fpow == 4) {
        v2=v*v;
        return v2*v2;
        
    } else if (fpow == 5) {
        v2=v*v;
        return v2*v2*v;
        
    } else if (fpow == 6) {
        v2=v*v;
        return v2*v2*v2;
        
    } else if (fpow == 7) {
        v2=v*v;
        return v2*v2*v2*v;
        
    } else if (fpow == 8) {
        v2=v*v;
        v4=v2*v2;
        return v4*v4;
        
    } else if (fpow == 9) {
        v2=v*v;
        v4=v2*v2;
        return v4*v4*v;
        
    } else if (fpow == 10) {
        v2=v*v;
        v4=v2*v2;
        vec3 v8=v4*v4;
        return v8*v2;        
    }
}

vec3 bloom(float Directions, float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = params.OriginalSize*0.2;
    float Pi = 6.28318530718; // Pi*2
    vec2 Radius = Size/iResolution.xy ;

    vec2 uv = vTexCoord;
    vec3 color  = vec3(0.0,0.0,0.0);//texture(Original, uv).rgb;
    vec3 lookup = vec3(0.0,0.0,0.0);//texture(Original, uv).rgb;
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( Original, uv + vec2(cos(d) -0.20  ,   sin(d))*Radius*i     ).rgb ;
            color +=pow3(lookup.rgb,fbloom_gamma);
            steps+=1.0;
        }
    }   
    color /= steps; //(Quality * Directions - 15.0);
    return color;
}


void main() {
    if (DO_BLOOM > 0.0 ) {
        FragColor = vec4(bloom(bloom_directions,bloom_quality,bloom_size,bloom_gamma),0.0);
    } else {
        FragColor = texture( Original, vTexCoord);
    }
}
