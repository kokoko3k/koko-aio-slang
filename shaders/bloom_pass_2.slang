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
layout(set = 0, binding = 2) uniform sampler2D Source;


vec3 pow(vec3 v, float p)
{
    return vec3(pow(v.x, p), pow(v.y, p), pow(v.z, p));
}

    vec3 int_pow3(vec3 v, float fpow){
        if ( fpow == 1.0 ) { return v; };
        if ( fpow == 2.0 ) { return v*v; }; 
        if ( fpow == 3.0 ) { return v*v*v; }; 
        if ( fpow == 4.0 ) { return v*v*v*v; }; 
        if ( fpow == 5.0 ) { return v*v*v*v*v; }; 
        if ( fpow == 6.0 ) { return v*v*v*v*v*v; }; 
        if ( fpow == 7.0 ) { return v*v*v*v*v*v*v; }; 
        if ( fpow == 8.0 ) { return v*v*v*v*v*v*v*v; }; 
        if ( fpow == 9.0 ) { return v*v*v*v*v*v*v*v*v; }; 
    }

vec3 bloom(float Directions, float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = params.SourceSize*0.2;
    float Pi = 6.28318530718; // Pi*2
    vec2 Radius = Size/iResolution.xy ;

    vec2 uv = vTexCoord;
    vec3 color  = vec3(0.0,0.0,0.0);//texture(Source, uv).rgb;
    vec3 lookup = vec3(0.0,0.0,0.0);//texture(Source, uv).rgb;
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( Source, uv+vec2(cos(d) -0.20 ,     sin(d))*Radius*i).rgb ;
            color +=int_pow3(lookup.rgb,fbloom_gamma);
            steps+=1.0;
        }
    }
    color /= (steps-1); //(Quality * Directions - 15.0);
    return color;
}

vec3 blur(float Directions, float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = params.SourceSize*0.2;
    float Pi = 6.28318530718; // Pi*2
    vec2 Radius = Size/iResolution.xy ;

    vec2 uv = vTexCoord;
    vec3 color  = vec3(0.0,0.0,0.0);//texture(Source, uv).rgb;
    vec3 lookup = vec3(0.0,0.0,0.0);//texture(Source, uv).rgb;
    float steps=0.0;
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( Source, uv+vec2(cos(d) -0.20 ,     sin(d))*Radius*i).rgb ;
            color +=lookup.rgb;
            steps+=1.0;
        }
    }
    color /= (steps-1); //(Quality * Directions - 15.0);
    return color;
}


void main() {
    if (DO_BLOOM > 0.0 ) {
        FragColor = vec4(blur(bloom_directions,bloom_quality,bloom_size,bloom_gamma),0.0);
    } else {
        FragColor = texture( Source, vTexCoord);
    }
}
