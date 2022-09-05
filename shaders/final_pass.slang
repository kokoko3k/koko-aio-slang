#version 450
#include "config.inc"
#define eps 1e-8

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

// 
#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D main_pass;
layout(set = 0, binding = 3) uniform sampler2D bloom_pass_final;
layout(set = 0, binding = 4) uniform sampler2D vignette_and_spot_pass;
layout(set = 0, binding = 5) uniform sampler2D ambi_temporal_pass;

#include "functions.include"

vec4 pixel_border() {
    vec3 ambi = texture(ambi_temporal_pass, vOutputCoord).rgb;
    float l = length(ambi);
    float sat = 1.25;
    float bright = 1.25;
    ambi =  normalize( pow(ambi.rgb + vec3(eps), vec3(sat)))*l * bright  ;
    ambi*=bright;
    return vec4(ambi,0.0);
}

vec3 ambi_noised() {
    return pixel_border().rgb + random();
}

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

vec4 main_wrap() {
    vec4 pixel_in = texture(main_pass, vOutputCoord);
    vec3 pixel_out = pixel_in.rgb;
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
        //float vignette = gauss_xy(0.0, 0.0, v_size, v_power, 0.0, 1.0);
        vec3 vignette = vec3(texture(vignette_and_spot_pass,vTexCoord).r);
        if (v_bypass < 1.0) pixel_out = vignette * pixel_out;
            else
        pixel_out = vignette ;
    }
    
    //Spot 
    if (DO_SPOT == 1.0) {
        DO_NOISE = true;
        //float spot =  gauss_xy(s_center_x, s_center_y, s_size, s_power, 0.0, 10.0);
        vec3 spot = vec3(texture(vignette_and_spot_pass,vTexCoord).g);
        if (s_bypass < 1.0) pixel_out = mix(pixel_out,vec3(1.0), spot);
            else
        pixel_out = vec3(spot) ;
    }

    //Deband
    if (DO_NOISE) pixel_out = pixel_out + random();
        
    //Out
    return vec4(pixel_out,pixel_in.a);
}

void main() {
    bool IsOuterFrame;
    vec4 psample = texture(main_pass, vOutputCoord);
    vec4 pixel_out;
    if ( border_needed() ) {
        IsOuterFrame = is_outer_frame(psample);
        if (IsOuterFrame)
            pixel_out = mark_outer_frame(vec3(0.0));
                else
            pixel_out = main_wrap();
    } else {
        pixel_out = main_wrap();
    }

    if (DO_AMBILIGHT == 1) {
        vec3 ambinoised = ambi_noised();  //Mix ambilight and noise
        if (IsOuterFrame) {
            //put ambilight on the outher frame
            FragColor = mark_outer_frame(ambi_noised()); 
        } else {
            //mix ambilight in the inner frame too, as curvature could shrink into the inner frame.
            FragColor = vec4(mix(ambinoised.rgb,pixel_out.rgb,min(pixel_out.a*1.5,1.0)),pixel_out.a);
        }
    } else {
        FragColor = pixel_out ;
    }
    
    
    /*if (params.OutputSize.y == 1920) {
    FragColor = vec4(1.0);
    }*/

}
