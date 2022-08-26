#version 450
#include "config.inc"


#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;

#include "functions.include"
void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = get_scaled_coords(TexCoord);
    vOutputCoord = TexCoord;
}


#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D main_pass;
layout(set = 0, binding = 4) uniform sampler2D bloom_pass_final;

vec3 pixel_alternate(vec3 source, float whiteness) {
    float line = vTexCoord.y * params.OutputSize.y;
    vec3 pixel_out = source;
    if  (int(mod(float(params.FrameCount),2.0  )) == 1) {
        if  (int(mod(line,2.0  )) == 1) pixel_out=mix(source,vec3(0), whiteness) ;
    } else {
        if  (int(mod(line,2.0  )) == 0) pixel_out=mix(source,vec3(0), whiteness) ;
    }
    return pixel_out;
}

float random() {
    // www.stackoverflow.com/questions/5149544/can-i-generate-a-random-number-inside-a-pixel-shader/
    vec2 seed = vTexCoord * params.FrameCount;
    vec2 i = vec2(23.140692, 2.6651442);
    return fract(cos(dot(seed, i)) * 123456.0f);
}

float gauss(float x, float x0, float sx, float size, float power){
    float arg = x-x0;
    arg = -(1/size)/2.*arg*arg/sx;
    float a = 1./(pow(2.*3.1415*sx, 0.5));
    return a*exp(arg) * power;
}

float gauss_xy(float pos_x, float pos_y, float size, float power, float gmin, float gmax) {
	vec2 uv = vTexCoord.xy + vec2(pos_x,pos_y);
	float scale_uv = params.SourceSize.x / params.SourceSize.y;
        float gx = gauss(uv.x* scale_uv,  0.5*scale_uv,  0.1,    size, power);
	float gy = gauss(uv.y,            0.5,           0.1,    size, power);
	float light = gx*gy;
	return clamp(light,gmin,gmax);
}

vec4 main_wrap() {
    vec3 pixel_out = texture(main_pass, vOutputCoord).rgb;
    vec3 bloomed;

    //Mix bloom texture
    if (DO_BLOOM == 1.0 ) {
        bloomed=texture(bloom_pass_final, vTexCoord).rgb ;
            
        if ( bloom_on_dark_only  == 1.0) {
           //float source_whiteness = (pixel_out.r+pixel_out.g+pixel_out.b) /3;
            float source_whiteness = (pixel_out.r+pixel_out.g+pixel_out.b);
            source_whiteness=min(source_whiteness,1.0);
            //Bloom must not darken the source:
                float bloom_light = bloomed.r+bloomed.g+bloomed.b;
                float pixel_light = pixel_out.r+pixel_out.g+pixel_out.b;
                if (bloom_light > pixel_light) pixel_out = mix(pixel_out,bloomed,BLOOM_MIX * (1-source_whiteness) );
        } else {
           pixel_out = mix(pixel_out,bloomed,BLOOM_MIX);
        }
    }

    //Black frame insertion
    if (DO_ALT_BLANK == 1.0 ) {
        pixel_out = pixel_alternate(pixel_out.rgb, ALT_BLANK_STRENGTH );
    }

 
    bool DO_NOISE = false;
    //vignette
    if (DO_VIGNETTE == 1.0) {
        DO_NOISE = true;
        float vignette = gauss_xy(0.0, 0.0, v_size, v_power, 0.0, 1.0);       
        if (v_bypass < 1.0) pixel_out = vec3(vignette) * pixel_out;
            else
        pixel_out = vec3(vignette) ;
    }
    
    //Spot 
    if (DO_SPOT == 1.0) {
        DO_NOISE = true;
        float spot =  gauss_xy(s_center_x, s_center_y, s_size, s_power, 0.0, 10.0);
        if (s_bypass < 1.0) pixel_out = mix(pixel_out,vec3(1.0), spot);
            else
        pixel_out = vec3(spot) ;
    }

    //Deband
    if (DO_NOISE) {
        float noise = random() * noisepower;
        pixel_out = pixel_out + noise;
    }
        
    //Out
    return vec4(pixel_out,0.0);
}

#include "functions.include"
void main() {
    vec4 psample = texture(main_pass, vOutputCoord);
    if ( border_needed() ) {
        if (is_outer_frame(psample))
            FragColor = mark_outer_frame(vec3(0.0));
                else
            FragColor = main_wrap();
    } else {
        FragColor = main_wrap();
    }

    /*if (params.OutputSize.y == 1920) {
    FragColor = vec4(1.0);
    }*/

}
