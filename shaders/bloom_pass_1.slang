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


vec3 pow3(vec3 v, float p)
{
    return vec3(pow(v.x, p), pow(v.y, p), pow(v.z, p));
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
