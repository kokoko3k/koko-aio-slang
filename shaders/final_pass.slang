#version 450
#include "config.inc"
#define eps 1e-8

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;
layout(location = 2) out float bezel_frame_lod;

#include "functions.include.slang"


void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = get_scaled_coords(TexCoord,global.FinalViewportSize, is_rotated());
    vOutputCoord = TexCoord;
    bezel_frame_lod = log2(global.monitor_bodySize.y * (BEZEL_FRAME_ZOOM+1.0) /global.FinalViewportSize.y);
}


#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 2) in float bezel_frame_lod;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 2) uniform sampler2D main_pass;
layout(set = 0, binding = 3) uniform sampler2D bloom_pass_final;
layout(set = 0, binding = 4) uniform sampler2D reflected_blurred_pass2;
layout(set = 0, binding = 5) uniform sampler2D ambi_temporal_pass;
layout(set = 0, binding = 6) uniform sampler2D avglum_pass;
layout(set = 0, binding = 7) uniform sampler2D monitor_body;


#include "functions.include.slang"

#define NOISE_A 12.9898
#define NOISE_B 78.233
#define NOISE_C 43758.5453

float displace(float power) {
    vec2 co = vTexCoord ;
    float dt = dot(co.xy, vec2(NOISE_A, NOISE_B));
    float sn = mod(dt,3.14);

    float noise_out = fract(sin(sn) * NOISE_C) - 0.5;
    noise_out = clamp(noise_out, -power, power);
    return noise_out ; 
}

float global_noise;

vec4 pixel_border() {
    vec3 ambi = texture(ambi_temporal_pass, vOutputCoord + global_noise ).rgb;
    return vec4(ambi,0.0);
}

vec3 ambi_noised() {
    return pixel_border().rgb;
}

vec3 pixel_alternate(vec3 source, float whiteness) {
    float line = vTexCoord.y * params.OutputSize.y;
    vec3 pixel_out = source;
    int l_period_half = int(ALT_BLANK_PERIOD) / 2;
    if  (int(mod(float(params.FrameCount),2.0  )) == 1) {
        if  ((mod(line,ALT_BLANK_PERIOD  )) > l_period_half) pixel_out=mix(source,vec3(0), whiteness) ;
    } else {
        if  ((mod(line,ALT_BLANK_PERIOD )) <= l_period_half) pixel_out=mix(source,vec3(0), whiteness) ;
    }
    return pixel_out;
}


float scale_to_range(float x, float dmin, float dmax) {
    //Scales 0..1 range to a..b range
    return ( (dmax-dmin) * x ) + dmin;
}

#define bezel_luminance bezel.r
vec3 bezel_color(float lum)  {
    vec3 col = vec3(BEZEL_R,BEZEL_G,BEZEL_B) + lum;
    float con_max =  0.5 * BEZEL_CON + 0.5;
    
    col.r = scale_to_range(col.r, -con_max+1, con_max); //contrast
    col.g = scale_to_range(col.g, -con_max+1, con_max); //contrast
    col.b = scale_to_range(col.b, -con_max+1, con_max); //contrast
    return clamp(col,0.0,1.0);
}

vec2 coords_curved = vTexCoord ; //FIXME how bad is this global variable?

vec3 compose_bezel_over(vec3 full_viewport) {

    vec2 coords_for_bezel = vTexCoord;
    vec2 coords_for_mirror = vOutputCoord;
    //vec2 coords_for_mirror =zoom(vOutputCoord,0.99);
    if (BEZEL_FRAME_ZOOM != 0.0)
        coords_for_bezel = zoomout_coords(vTexCoord,-BEZEL_FRAME_ZOOM,1.0);

    //No need to draw anything outside this:
    if (coords_for_bezel.x < 0  || coords_for_bezel.y < 0 || coords_for_bezel.x > 1.0 || coords_for_bezel.y > 1.0) return full_viewport;

    //Main lut:
    vec4 bezel = textureLod(monitor_body,coords_for_bezel,bezel_frame_lod);

    //No need to draw anything on full alpha:
    if (bezel.a == 0.0) return full_viewport;

    //We use the red component of the bezel to express its luminance (define bezel_luminance bezel.r)
    vec3 bezel_colored = bezel_color(bezel_luminance);

    //This is the reflection to be composed over the bezel);
    vec3 pixel_mirrored = texture(reflected_blurred_pass2,
                          coords_for_mirror + displace( global.FinalViewportSize.z ) ).rgb;

    //Take the reflection modifier from the texture blue component into account; it is/may be used to lower the reflection in the corners.
        //float reflection = (reflection_shade * 1.4 -  0.4)  * bezel.b ;
        //reflection = clamp (reflection, 0.0, 1.0);
        float reflection = bezel.b;

        vec3 bezel_out = bezel_colored + (pixel_mirrored * reflection * 0.5) ;

    //Mix a bit of ambient light over the bezel
        vec4 pixel_avglum = texture(avglum_pass,vOutputCoord);
        bezel_out = bezel_out + (pixel_avglum.rgb * 0.05);

    //We use the green component to express Hardness/Specularity; there the reflection will be completely diffused.
    //For the task, we use a mipmap whit adeguate precision.
        float lut_hardness = bezel.g;
        if (lut_hardness > 0.0) {
            bezel_out = bezel_out + ( ( pixel_avglum.rgb + pixel_avglum.a*0.5)       * lut_hardness/3.5);
        } 
         
    return mix(full_viewport, bezel_out, bezel.a);
}
// 
vec4 pixel_inner_frame() {
    vec4 pixel_in = texture(main_pass, vOutputCoord);
    vec3 pixel_out = pixel_in.rgb;
    vec3 bloomed;

    //Curvature
        if (DO_CURVATURE == 1.0) {
            if ((GEOM_WARP_X > 0.0) || (GEOM_WARP_Y > 0.0))
                coords_curved = Warp(coords_curved,GEOM_WARP_X,GEOM_WARP_Y);
        }
        
        if (DO_BEZEL == 1.0) {
            coords_curved = zoomout_coords(coords_curved, -BEZEL_INNER_ZOOM , 1.0);
        }
    
    //Mix bloom texture
        if (DO_BLOOM == 1.0 ) {
            bloomed=texture(bloom_pass_final, coords_curved).rgb ;
            if (BLOOM_BYPASS == 1.0)
                pixel_out = bloomed;
            else {
                float over_white_correction = 1.0;
                if (BLOOM_OVER_WHITE < 1.0) {
                        float b_brightness = max(pixel_out.b,max(pixel_out.r,pixel_out.g));

                        b_brightness *= 1-BLOOM_OVER_WHITE;
                        over_white_correction = 1.0 - b_brightness;

                }
                pixel_out = pixel_out - (bloomed * BLOOM_MIX * over_white_correction);
            }
        }

    //Black frame insertion
        if (DO_ALT_BLANK == 1.0 ) {
            pixel_out = pixel_alternate(pixel_out.rgb, ALT_BLANK_STRENGTH );
        }

    //vignette and spot
        if (DO_VIGNETTE + DO_SPOT >0.0) {
            float in_aspect = get_in_aspect();
            
            if (DO_VIGNETTE == 1.0) {
                float vignette;
                float dist = length(vec2((coords_curved.x-0.5)*in_aspect,coords_curved.y-0.5)); //dist = length(vec2(coords_curved.x*in_aspect-(in_aspect*0.5),coords_curved.y-0.5));
                vignette = smoothstep(V_SIZE,0.0,dist)*V_POWER+global_noise;
                if (V_BYPASS < 1.0) pixel_out = vignette * pixel_out;
                    else
                pixel_out = vec3(vignette);
            }

            if (DO_SPOT == 1.0) {
            float spot;
            vec2 s_offset = vec2(-S_CENTER_X,-S_CENTER_Y);
            float dist = length(vec2((coords_curved.x-0.5)*in_aspect,coords_curved.y-0.5)+s_offset); //dist = length(vec2(coords_curved.x*in_aspect-in_aspect*0.5),coords_curved.y-0.5));
            spot = smoothstep(S_SIZE,0.0,dist)*S_POWER+global_noise;
            if (S_BYPASS < 1.0) pixel_out = spot + pixel_out;
                else
            pixel_out = vec3(spot);
            }
            
        }

    //Border
        float border_inner_frame = 1.0;
        if (DO_BEZEL==1.0 || DO_CURVATURE == 1.0)
            border_inner_frame = border(coords_curved);

        float pixel_out_alpha = pixel_in.a * border_inner_frame;
        
    //Out
        return vec4(pixel_out,pixel_out_alpha) * border_inner_frame;
}


vec4 main_wrap(){
    /* Handle inner border and outer border, not bezel */
    if (DO_VIGNETTE + DO_SPOT + DO_AMBILIGHT >0.0) global_noise = random(NOISEPOWER);
    //Just do pixel_inner_frame() and exit when there is no need to paint border.
    if (!border_needed()) return pixel_inner_frame();

    //From now on, we need a border.
        bool bIs_outer_frame = ((vTexCoord.x < 0.0) || (vTexCoord.x > 1.0));
        
        //Handle outer frame cases
            //if we want ambilights in the outer frame, draw it and return
            if ((bIs_outer_frame) && (DO_AMBILIGHT == 1))
                return vec4(ambi_noised(),1.0);
            
            //But if it is just outer frame, just make it black.
            if (bIs_outer_frame) return vec4(0.0);

        
        //Handle inner frame cases
            vec4 vPixel_inner_frame = pixel_inner_frame();
            if (DO_AMBILIGHT == 1) {
                //mix ambilight in the inner frame too, as curvature could shrink into the inner frame.
                bool draw_leds = true;
                //Not painting ambilights here is the best way to cheaply draw a border around the frame
                if (DO_BEZEL == 1.0) {
                    vec2 vTexCoord_zoomout = zoomout_coords(vTexCoord, -BEZEL_INNER_ZOOM , 1.0);
                    float border_start = 1-BEZEL_IMAGE_BORDER;
                    //Not using coords_curved here because crazy things would happen with vertical games
                    draw_leds = vTexCoord_zoomout.x < border_start || vTexCoord_zoomout.x > BEZEL_IMAGE_BORDER || 
                                vTexCoord_zoomout.y < border_start || vTexCoord_zoomout.y > BEZEL_IMAGE_BORDER ;
                }
                if (draw_leds) 
                    return vec4(mix(ambi_noised().rgb,vPixel_inner_frame.rgb,min(vPixel_inner_frame.a*1.5,1.0)),vPixel_inner_frame.a);
                //return vec4(1.0,0.0,0.0,1.0);
            }

            //Last case, inner border without ambilight:
            return vPixel_inner_frame;
}


void main() {
    //"Just" handle inner and outer frame here:
    vec4 pixel_out = main_wrap();
    
    //Bezel
    if (DO_BEZEL == 1.0) {
        pixel_out = vec4(compose_bezel_over(pixel_out.rgb),1.0);
    }

    FragColor = pixel_out ;
                      
    //FragColor = texture(reflected_blurred_pass2, vOutputCoord);
    
}
