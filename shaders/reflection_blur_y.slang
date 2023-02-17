#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vWarp_vexp;
layout(location = 2) out vec2 vWarp_arg2;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   //Precalc some Curvature/Warp values:
      vWarp_vexp = 1.0/ (1 + (vec2(GEOM_WARP_X, GEOM_WARP_Y) * 0.2)) ;
      vWarp_arg2 = 1.0 - pow(vec2(0.29289321881345247559915563789515), vWarp_vexp );
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vWarp_vexp;
layout(location = 2) in vec2 vWarp_arg2;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 1) uniform sampler2D first_pass;
layout(set = 0, binding = 2) uniform sampler2D Source;

#include "includes/functions.include.slang"

#define SourceTexture Source
#define SourceTextureSize params.SourceSize

#define b_offset_x -0.05
#define Pi2 6.28318530717959
vec3 blur(float Quality, float Directions, float Size, vec2 co) {
    Size = Size * NEW_SCALEMOD_Y;
    vec4 iResolution = SourceTextureSize;
    vec2 Radius = Size/iResolution.xy ;
    vec3 color  = vec3(0.0,0.0,0.0);
    vec3 lookup = vec3(0.0,0.0,0.0);
    float steps=0.0;
    for( float d=0.0; d<Pi2; d+=Pi2/Directions) {
        for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality) {
            lookup = texture( SourceTexture, co + vec2(cos(d)  + b_offset_x , sin(d))*Radius*i  ).rgb ;
            color +=lookup.rgb;
            steps+=1.0;
        }
    }
    color /= steps;
    return color;
}

vec3 blur_unroll(float Size, vec2 co) {
    Size = Size * NEW_SCALEMOD_Y;
    vec3 color  = vec3(0.0,0.0,0.0);    
    vec2 d = SourceTextureSize.zw * Size;
    color =  texture( SourceTexture, co + d * vec2(-1.0,   1.0 )).rgb ;
    color += texture( SourceTexture, co + d * vec2( 1.0,   1.0 )).rgb ;
    color += texture( SourceTexture, co + d * vec2(-1.0,  -1.0 )).rgb ;
    color += texture( SourceTexture, co + d * vec2( 1.0,  -1.0 )).rgb ;
    color /= 4.0;
    return color;
}

void main() {
    
    if (DO_BEZEL == 0.0) return;
    vec4 pixel_source = texture(Source, vTexCoord);
    if (is_useless(pixel_source)) return;
    
    vec2 co_adapted = zoom(vTexCoord, BEZEL_REFL_ZOOM);
    if (DO_CURVATURE == 1.0) {
        if ((GEOM_WARP_X > 0.0) || (GEOM_WARP_Y > 0.0))
            co_adapted = Warp_fast(co_adapted, vWarp_vexp, vWarp_arg2); //coords_curved = Warp(coords_curved,GEOM_WARP_X,GEOM_WARP_Y);
    }
    co_adapted = zoomout_coords(co_adapted, BEZEL_BORDER_SIZE , 1.0);

    vec3 pixel_blur = blur_unroll(3.3,vTexCoord);
    vec3 pixel_sharp = texture( first_pass, co_adapted).rgb;
    pixel_sharp = apply_fuzzy_main_pass(pixel_sharp);

    pixel_source.a = pow(pixel_source.a, 0.3);
    vec3 pixel_out = mix(pixel_sharp, pixel_blur, pixel_source.a);

    FragColor = vec4(pixel_out, 1.0);
}
 
 
  
