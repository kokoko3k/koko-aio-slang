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
layout(set = 0, binding = 2) uniform sampler2D main_pass;
layout(set = 0, binding = 4) uniform sampler2D bloom_pass_final;

vec3 pixel_alternate(vec3 source, float whiteness) {
    float line = vTexCoord.y * params.OutputSize.y;
    vec3 pixel_out = source;
    if  (int(mod(float(params.FrameCount),2.0  )) == 1) {
        if  (int(mod(line,2.0  )) == 1) {
            pixel_out=mix(source,vec3(0), whiteness) ;
        }
    } else {
        if  (int(mod(line,2.0  )) == 0) {
            pixel_out=mix(source,vec3(0),whiteness) ;
        }
    }
    return pixel_out;
}




// www.stackoverflow.com/questions/5149544/can-i-generate-a-random-number-inside-a-pixel-shader/

float random(vec2 seed)
{
	vec2 i = vec2(23.140692, 2.6651442);
	return fract(cos(dot(seed, i)) * 123456.0f);
}



float gauss(float x, float x0, float sx, float size, float power){
    float arg = x-x0;
    arg = -(1/size)/2.*arg*arg/sx;
    float a = 1./(pow(2.*3.1415*sx, 0.5));
    return a*exp(arg) * power;
}


// Spot da aggiungere 
#define spot_center_x -0.4
#define spot_center_y 0.4
#define spot_g_size 0.15
#define spot_g_power 0.25
#define spot_l_min 0.0
#define spot_l_max 1.0
#define spot_g_bypass 0.0

// non-uniformità del pannello, da moltiplicare
#define vignette_noisepower 0.015
#define vignette_center_x -0.0
#define vignette_center_y 0.0
#define vignette_g_size 12
#define vignette_g_power 0.8
#define vignette_l_min 0.1
#define vignette_l_max 1.0
#define vignette_g_bypass 0.0


#define noisepower 0.015
#define center_x -0.0
#define center_y 0.0
#define g_size 12
#define g_power 0.8
#define l_min 0.1
#define l_max 1.0
#define g_bypass 0.0

void main(void) {
    vec3 pixel_out = texture(main_pass, vTexCoord).rgb;
    vec3 bloomed;

    //Mix bloom texture
    if (DO_BLOOM == 1.0 ) {
        bloomed=texture(bloom_pass_final, vTexCoord).rgb ;
            
        if ( bloom_on_dark_only  == 1.0) {
           //float source_whiteness = (pixel_out.r+pixel_out.g+pixel_out.b) /3;
           float source_whiteness = (pixel_out.r+pixel_out.g+pixel_out.b);
           source_whiteness=min(source_whiteness,1.0);
           pixel_out = mix(pixel_out,bloomed,BLOOM_MIX * (1-source_whiteness) );
        } else {
           pixel_out = mix(pixel_out,bloomed,BLOOM_MIX);
        }
    }

    //Black frame insertion
    if (DO_ALT_BLANK == 1.0 ) {
        pixel_out = pixel_alternate(pixel_out.rgb, ALT_BLANK_STRENGTH );
    }

    
    //vignette
    vec2 uv = vTexCoord.xy + vec2(vignette_center_x,vignette_center_y);
    float scale_uv = params.SourceSize.x / params.SourceSize.y;
    float gx = gauss(uv.x* scale_uv,         0.5*scale_uv,       0.1, vignette_g_size, vignette_g_power);
    float gy = gauss(uv.y, 0.5, 0.1, vignette_g_size, vignette_g_power);
    float light = gx*gy;
    light = clamp(light,vignette_l_min,vignette_l_max);
    vec2 randseed = vTexCoord * params.FrameCount;
    float noise = random(randseed) * noisepower;
    light+=noise;
    if (vignette_g_bypass < 1.0) {
        pixel_out = vec3(light) * pixel_out;
    } else {
        pixel_out = vec3(light) ;
    }
    
    //Spot
    uv = vTexCoord.xy + vec2(spot_center_x,spot_center_y);
    scale_uv = params.SourceSize.x / params.SourceSize.y;
    gx = gauss(uv.x* scale_uv,         0.5*scale_uv,       0.1, spot_g_size, spot_g_power);
    gy = gauss(uv.y, 0.5, 0.1, spot_g_size, spot_g_power);
    light = gx*gy;
    light = clamp(light,spot_l_min,spot_l_max);
    randseed = vTexCoord * params.FrameCount;
    noise = random(randseed) * noisepower;
    light+=noise;
    if (spot_g_bypass < 1.0) {
        pixel_out = vec3(light) + pixel_out;
    } else {
        pixel_out = vec3(light) ;
    }
    
    

    
    
    //Out
    FragColor = vec4(pixel_out,0.0);
}
