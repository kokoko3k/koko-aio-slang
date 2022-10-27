#version 450
#include "config.inc"
#define eps 1e-8

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;
layout(location = 4) out vec2 spot_offset;

#include "includes/functions.include.slang"

void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = get_scaled_coords(TexCoord,global.FinalViewportSize, is_rotated())+vec2(0.00001);
    vOutputCoord = TexCoord;;
    spot_offset = offsets_from_float(S_POSITION+420.0,40);
    spot_offset = spot_offset / 10.0 + vec2(0.0,1.0);
}


#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 4) in vec2 spot_offset;
layout(location = 0) out vec4 FragColor;


//layout(set = 0, binding = 2) uniform sampler2D main_pass;
layout(set = 0, binding = 3) uniform sampler2D bloom_pass_final;
layout(set = 0, binding = 4) uniform sampler2D reflected_blurred_pass2;
layout(set = 0, binding = 5) uniform sampler2D ambi_temporal_pass;
layout(set = 0, binding = 6) uniform sampler2D avglum_pass;
layout(set = 0, binding = 7) uniform sampler2D monitor_body;
layout(set = 0, binding = 8) uniform sampler2D bg;
layout(set = 0, binding = 9) uniform sampler2D first_pass;

//Ex main_pass layouts:
    layout(set = 0, binding = 10) uniform sampler2D FXAA_pass;
    layout(set = 0, binding = 11) uniform sampler2D in_glow_pass;
    layout(set = 0, binding = 12) uniform sampler2D halo_pass;
    //layout(set = 0, binding = 13) uniform sampler2D first_pass;
    layout(set = 0, binding = 14) uniform sampler2D avglum_passFeedback;

//Ex main_pass defines:
    #define half_pi 1.5707963267949
    
    // RGB mask:       R     G     B
    #define m1 vec3 ( 1.0 , 0.0 , 0.0 )    //col 1
    #define m2 vec3 ( 0.0 , 1.0 , 0.0 )    //col 2
    #define m3 vec3 ( 0.0 , 0.0 , 1.0  )   //col 3

    // RGB mask low dpi (green-magenta, exploiting native rgb subpixels)
    #define m1gm vec3 ( 0.0 , 1.0 , 0.0 )    //col 1
    #define m2gm vec3 ( 1.0 , 0.0 , 1.0 )    //col 2

#include "includes/functions.include.slang"

    
vec2 coords_curved = vTexCoord ; //FIXME how bad is this global variable?
    
vec3 pixel_vmask(vec3 source, vec3 white_reference, float over_white) {
    int col = int( vOutputCoord.x * params.OutputSize.x );
    vec3 pixel_out;
    vec3 vmasked;
    vec4 vec_mod=(vec4(3,1,2,3) + vec4(VMASK_GAP,0.0,0.0,0.0))* VMASK_DARKLINE_SCALE ;
    float mask_lightness = 1.0 - RGB_MASK_STRENGTH;
    if ( mod(col, vec_mod.x) < vec_mod.y)         vmasked = min(m1 + mask_lightness,vec3(1.0)) * source;
        else if (mod(col, vec_mod.x) < vec_mod.z) vmasked = min(m2 + mask_lightness,vec3(1.0)) * source;
        else if (mod(col, vec_mod.x) < vec_mod.w) vmasked = min(m3 + mask_lightness,vec3(1.0)) * source;
    else vmasked = min(vec3(0.0) + mask_lightness,vec3(1.0)) * source;

    if (over_white == 1.0) pixel_out = vmasked;
        else {
            float whiteness=(white_reference.r+white_reference.g+white_reference.b)/3.0;
            whiteness-= over_white;
            whiteness=  clamp(whiteness,0.0,1.0);
            pixel_out=  mix(vmasked,source,whiteness);
        }
   return pixel_out;
}

vec3 pixel_vmask_gm(vec3 source, vec3 white_reference, float over_white) {
    int col = int( vOutputCoord.x * params.OutputSize.x );
    vec3 pixel_out;
    vec3 vmasked;
    vec3 vec_mod=(vec3(2,1,2) + vec3(VMASK_GAP,0.0,0.0))* VMASK_DARKLINE_SCALE ;
    
    float mask_lightness = 1.0 - RGB_MASK_STRENGTH;
    if (mod(col, vec_mod.x) < vec_mod.y)          vmasked = min(m1gm + mask_lightness,vec3(1.0)) * source;
        else if (mod(col, vec_mod.x) < vec_mod.z) vmasked = min(m2gm + mask_lightness,vec3(1.0)) * source;
    else vmasked = min(vec3(0.0) + mask_lightness,vec3(1.0)) * source;

    if (over_white == 1.0) pixel_out = vmasked;
        else {
            float whiteness=(white_reference.r+white_reference.g+white_reference.b)/3.0;
            whiteness-= over_white;
            whiteness=  clamp(whiteness,0.0,1.0);
            pixel_out=  mix(vmasked,source,whiteness);
        }
    
   return pixel_out;
}

vec3 pixel_darklines(vec3 source,float darkline_every, float darkline_trans,
                     float do_offset, vec3 white_reference,float over_white) {

    float Darkline_part_w = (3.0 - VMASK_USE_GM + VMASK_GAP) * VMASK_DARKLINE_SCALE;
    float Darkline_part_w_x2 = Darkline_part_w*2;
    //vec3 pixel_out=source;
    float col_2 =  vOutputCoord.x * params.OutputSize.x;
    float line_2 = vOutputCoord.y * params.OutputSize.y;

    darkline_every *= VMASK_DARKLINE_SCALE;

    if (over_white != 1.0) {
        //less effect on bright colors.
        float whiteness=(white_reference.r+white_reference.g+white_reference.b)/3.0;
        darkline_trans+=(whiteness-over_white);
        darkline_trans=clamp(darkline_trans,0.0,1.0);
    }

    if (do_offset == 1.0) {
        if  (int(mod(line_2, darkline_every)) < VMASK_DARKLINE_SCALE) {
            if (int(mod(col_2, Darkline_part_w_x2)) < Darkline_part_w) return source * darkline_trans;
        } else if  (int(mod(line_2+(darkline_every/2), darkline_every)) < VMASK_DARKLINE_SCALE ) {
            // DRAW WITH OFFSET:
            col_2+=Darkline_part_w;
            if ((int(mod(col_2, Darkline_part_w_x2))) < Darkline_part_w)
                return source * darkline_trans;
        }
    } else {

        if ( darkline_every >= 0.0)
            if (int(mod(line_2, darkline_every)) < VMASK_DARKLINE_SCALE) return source * darkline_trans;
    }
    return source;
}

float scanline_shape(vec2 coords, bool do_flicker) {
    bool alternate = false;
    float period = 1.0;
    
    int slow = 1;
    
    if (do_flicker) {
        if (params.FrameCount/slow % 2 == 0.0) alternate = true;
        if (params.OriginalSize.y > MIN_LINES_INTERLACED )  period = 0.5;
    }

    float angle = coords.y * pi * params.OriginalSize.y * period;

    float lines;
    if (alternate)
        lines = -sin(angle+half_pi); //lines = abs(cos(angle));
             else
        lines = sin(angle);
    lines = (lines*lines);
  
    if (SCANLINE_DARK >= 0.0) {
        lines = lines * (1.0 - SCANLINE_DARK) + SCANLINE_DARK;
    } else {        
        float deepness = -SCANLINE_DARK;
        lines = lines * ((1-SCANLINE_DARK) ) + SCANLINE_DARK ;
    }
    
    return lines;
}

vec4 main_pass_main_wrap(vec2 co) {
    bool isinterlaced = is_interlaced();
    bool flickering_scanlines = (DO_SCANLINES == 1.0) && scanline_have_to_flicker(isinterlaced) ;


    vec3 pixel_in;
    vec3 pixel_glowed;
    
    //Get the first available pixel_in:
    if  (DO_IN_GLOW == 1.0) {
            pixel_glowed = texture(in_glow_pass,co).rgb;
            pixel_in = pixel_glowed;
        }
            else if (DO_FXAA == 1.0) 
        pixel_in = texture(FXAA_pass,co).rgb ;
            else
        pixel_in = texture(first_pass,co).rgb ;

    vec3 pixel_out = pixel_in;
    vec3 pixel_in_clamped = min(pixel_in,vec3(1.0)); //Clamp here for moth vmask and darklines.
    
    //Mask and darklines:
    if (DO_VMASK_AND_DARKLINES == 1.0 ) {
        if (RGB_MASK_STRENGTH > 0.0) {
            //Use RGB pattern or exploit RGB layout with green and magenta?
            if (VMASK_USE_GM < 1.0) {
                pixel_out = pixel_vmask(pixel_in, pixel_in_clamped, VMASK_OVERWHITE);
            } else {           
                pixel_out = pixel_vmask_gm(pixel_in, pixel_in_clamped, VMASK_OVERWHITE);
            }
        }
        //Screen lines
        if (DARKLINES_STRENGTH > 0.0 ) {
            float MYDARKLINES_TRANSPARENCY = 1.0 - DARKLINES_STRENGTH;
            pixel_out = pixel_darklines(pixel_out,DARKLINES_PERIOD,MYDARKLINES_TRANSPARENCY,DO_DARKLINES_VOFFSET,pixel_in_clamped,DRKLN_OVERWHITE);
        }

    }
    
    //Halo
    vec3 pixel_haloed;
    if (DO_HALO == 1.0 ) {
        pixel_haloed = texture(halo_pass,co).rgb;
        pixel_out += pixel_haloed;
        pixel_out = clamp(pixel_out,0.0,HALO_CLAMP);
    }
    
    // Non flickering scanlines
    if ( DO_SCANLINES == 1.0 )  {
        vec3 pixel_bleed ; 
        if  (! ( isinterlaced  && (SCANLINE_DISABLE_ON_INTERLACE == 1.0))  ) {
            if (DO_IN_GLOW + DO_HALO > 0.0) {
                if (DO_HALO == 1.0) pixel_bleed = pixel_haloed;
                else if (DO_IN_GLOW == 1.0) pixel_bleed = pixel_glowed;
                else pixel_bleed = pixel_in;
            }
        
            float scanline_shape =  scanline_shape(co, flickering_scanlines ) ;
            vec3 pixel_scanlined = scanline_shape * pixel_out;

            pixel_out = pixel_scanlined + (pixel_out * pixel_bleed *  SCANLINES_BLEEDING * (1-scanline_shape));
        }
    }
  
    if (DO_CCORRECTION == 1.0) pixel_out = pow(pixel_out,vec3(GAMMA_OUT));

    //Out
    return vec4(pixel_out,1.0) ; //* border(border_coords);
}

vec4 pixel_main_pass() {
    vec2 coords = vTexCoord;
    
    if (DO_DYNZOOM == 1.0) {
        float zoomin = 1.0 + (texture(avglum_passFeedback, vec2(0.25,0.25)    ).a/ DYNZOOM_FACTOR);
        coords = zoom(vTexCoord, zoomin);
    }
    
        if (DO_BEZEL == 1.0) {
            coords = zoomout_coords(coords, -BEZEL_INNER_ZOOM , 1.0);
        }
    
   //FIXME: bezel may need a wider border when zoomed in.
            //But for performance reasons we can wide the border in relation to the desidered reflection area.
            //by now, just wide by BEZEL_REFLECTION_AREA_SIZE defined in config.inc

    bool is_border = false;
    
    if (border_needed()) {

        float WIDEN = DO_BEZEL * BEZEL_REFLECTION_AREA_SIZE;
        bool b_is_rotated = is_rotated();
        bool is_outside_x = ((coords.x > 1.0+WIDEN ) || (coords.x < 0.0 - WIDEN) );
        bool is_outside_y = ((coords.y > 1.0+WIDEN ) || (coords.y < 0.0 - WIDEN) );
        is_border = (b_is_rotated && is_outside_y) || (!b_is_rotated && is_outside_x);
   }
   
   if (is_border)
       return mark_outer_frame(vec3(0.0));
   else
       return main_pass_main_wrap(coords_curved);
}




































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

vec4 pixel_background_image(){
    vec2 tex_size = textureSize(bg, 0);
    float bg_lod = log2(tex_size.y / global.FinalViewportSize.y);
    vec2 back_coords =  get_scaled_coords_aspect(vOutputCoord,global.FinalViewportSize, tex_size.x/tex_size.y, is_rotated());
    back_coords=zoom(back_coords,1.0);
    return textureLod(bg,back_coords,bg_lod);
}

vec3 ambi_noised() {
    return texture(ambi_temporal_pass, vOutputCoord + global_noise ).rgb;
}


vec3 pixel_border(bool image_over) {
    vec3 pixel_out = vec3(0.0);
    if (DO_AMBILIGHT == 1.0)
        pixel_out = ambi_noised();
    if (DO_BG_IMAGE == 1.0 && !image_over)
        pixel_out += pixel_background_image().rgb;
    return pixel_out;
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


#define bezel_luminance bezel.r
vec3 bezel_color(float lum)  {
    vec3 col = vec3(BEZEL_R,BEZEL_G,BEZEL_B) + lum;
    float con_max =  0.5 * BEZEL_CON + 0.5;
    
    col.r = scale_to_range(col.r, -con_max+1, con_max); //contrast
    col.g = scale_to_range(col.g, -con_max+1, con_max); //contrast
    col.b = scale_to_range(col.b, -con_max+1, con_max); //contrast
    return clamp(col,0.0,1.0);
}

vec3 compose_bezel_over(vec3 full_viewport) {
    vec2 bezel_lut_size = textureSize(monitor_body,0);
    float bezel_frame_lod = log2(bezel_lut_size.y * (BEZEL_FRAME_ZOOM+1.0) /global.FinalViewportSize.y);
    vec2 coords_for_bezel = vTexCoord;
    //vec2 coords_for_mirror;
    //vec2 coords_for_mirror =zoom(vOutputCoord,0.99);
    if (BEZEL_FRAME_ZOOM != 0.0)
        coords_for_bezel = zoomout_coords(vTexCoord,-BEZEL_FRAME_ZOOM,1.0);

    vec2 coords_for_mirror = coords_for_bezel;
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
                          coords_for_mirror + displace( min(global.FinalViewportSize.z,global.FinalViewportSize.w) ) ).rgb;

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
    vec4 pixel_in = pixel_main_pass();
    vec3 pixel_out = pixel_in.rgb;
    vec3 bloomed;
  
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
                        over_white_correction =1- b_brightness;
                }
                pixel_out = pixel_out + (bloomed * BLOOM_MIX * over_white_correction);
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
            float dist = length(vec2((coords_curved.x-0.5)*in_aspect,coords_curved.y-0.5)+spot_offset); //dist = length(vec2(coords_curved.x*in_aspect-in_aspect*0.5),coords_curved.y-0.5));
            spot = smoothstep(S_SIZE,0.0,dist)*S_POWER+global_noise;
            if (S_BYPASS < 1.0) pixel_out = spot + pixel_out;
                else
            pixel_out = vec3(spot);
            }
            
        }

    //Border (edge)
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
            if (bIs_outer_frame)              
                if (border_needed())
                    return vec4(pixel_border(BG_IMAGE_OVER == 1.0),1.0);
                            
            
            //But if it is just outer frame, just make it black.
            if (bIs_outer_frame) return vec4(0.0);

        
        //Handle inner frame cases
            vec4 vPixel_inner_frame = pixel_inner_frame();
            if (border_needed()) {
                //mix ambilight in the inner frame too, as curvature could shrink into the inner frame.
                bool draw_border = true;
                //Not painting ambilights here is the best way to cheaply draw a border around the frame
                if (DO_BEZEL == 1.0) {
                    vec2 vTexCoord_zoomout = zoomout_coords(vTexCoord, -BEZEL_INNER_ZOOM , 1.0);
                    float border_start = 1-BEZEL_IMAGE_BORDER;
                    //Not using coords_curved here because crazy things would happen with vertical games
                    draw_border = vTexCoord_zoomout.x < border_start || vTexCoord_zoomout.x > BEZEL_IMAGE_BORDER || 
                                vTexCoord_zoomout.y < border_start || vTexCoord_zoomout.y > BEZEL_IMAGE_BORDER ;
                }
                if (draw_border) 
                    return vec4(mix(pixel_border(BG_IMAGE_OVER == 1.0).rgb,vPixel_inner_frame.rgb,min(vPixel_inner_frame.a*1.5,1.0)),vPixel_inner_frame.a);
                //return vec4(1.0,0.0,0.0,1.0);
            }

            //Last case, inner border without ambilight:
            return vPixel_inner_frame;
}


void main() {
    //For debug purposes:
        //quad split screen
        //if ( (vTexCoord.x < 0.5  && vTexCoord.y > 0.5) || (vTexCoord.x > 0.5  && vTexCoord.y < 0.5)         ) pixel_out = texture(first_pass,vTexCoord);
        //split screen (debug)
        //if (vTexCoord.y < 0.5) pixel_out = texture(first_pass,vTexCoord);
    
    
    //Curvature
    if (DO_CURVATURE == 1.0) {
        if ((GEOM_WARP_X > 0.0) || (GEOM_WARP_Y > 0.0))
            coords_curved = Warp(coords_curved,GEOM_WARP_X,GEOM_WARP_Y);
    }

    if (DO_BEZEL == 1.0) {
        coords_curved = zoomout_coords(coords_curved, -BEZEL_INNER_ZOOM , 1.0);
    }  
    
    //"Just" handle inner and outer frame here:
    vec4 pixel_out = main_wrap();

    
    if (DO_BEZEL == 1.0) {
        pixel_out = vec4(compose_bezel_over(pixel_out.rgb),1.0);
    }
    
    if (DO_BG_IMAGE == 1.0 && BG_IMAGE_OVER==1.0) {
        vec4 bg_image = pixel_background_image();
        pixel_out = mix(pixel_out,bg_image,bg_image.a);
    }

    FragColor = pixel_out;
}
