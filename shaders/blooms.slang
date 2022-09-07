#include "pows.slang"
#define Pi  (3.14159265358979*2)
#define bloom_directions 8

#define b_offset_x -0.05 //Why is this needed by bloom?


vec3 bloom(float Directions, float Quality, float Size, float fbloom_gamma) {
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;

    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    vec3 fbloom_gamma_vec3=vec3(fbloom_gamma);
    for( float d=0.0; d<Pi; d+=Pi/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, vTexCoord + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color = color + my_pow(lookup.rgb,fbloom_gamma);

        steps+=1.0;
        }
    }
    color /= (steps-1);
    return color;
}







