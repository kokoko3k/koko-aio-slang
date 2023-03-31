#version 450

/* This pass:
 * Composes the previous passes
 * Does masks, spot, bezel, vignette, background image (anything else?)
 */

#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;


layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;
layout(location = 2) out vec2 spot_offset;
layout(location = 3) out vec2 vFragCoord;
layout(location = 4) out float vIsRotated;


//Curvature:
    layout(location = 5) out vec2 vWarp_vexp;
    layout(location = 6) out vec2 vWarp_arg2;

//Scanlines:
    layout(location = 7) out float vIsInterlaced;
    layout(location = 8) out float vFlickeringScanlines;
    layout(location = 9) out float vScanlinePeriod;
    layout(location = 10) out float vScanlinesAlternate;

//Vignette, spot:
    layout(location = 11) out float vIn_aspect;

layout(location = 12) out float vBEZEL_INNER_ZOOM_adapted;

#include "includes/functions.include.slang"


void main() {
    gl_Position = global.MVP * Position;
    vIsRotated = float(is_rotated());
    vIn_aspect = get_in_aspect();
    

    
    
    //Calculate vTexcoord as fractional or integer scaled?
        if ( !do_integer_scale() )
            vTexCoord = get_scaled_coords_aspect(TexCoord,global.FinalViewportSize, vIn_aspect, bool(vIsRotated)) + vec2(0.0001);
                else
            vTexCoord = integer_scale(TexCoord, vIn_aspect, bool(vIsRotated)) + vec2(0.0001); //<- without the offset, SCANLINE_MIN doesn't work.

                        
        
    //if (DO_GLOBAL_SHZO >0.5)
    //    vTexCoord = zoom(vTexCoord + vec2(-GLOBAL_OFFX, -GLOBAL_OFFY), GLOBAL_ZOOM );
    //..unbranched previous
    vTexCoord = (zoom(vTexCoord + vec2(-GLOBAL_OFFX, -GLOBAL_OFFY), GLOBAL_ZOOM ) * DO_GLOBAL_SHZO) + 
                (vTexCoord * (1-DO_GLOBAL_SHZO) );

    vOutputCoord = TexCoord;

    vFragCoord = vec2( floor(vOutputCoord.x * params.OutputSize.x),
                       floor(vOutputCoord.y * params.OutputSize.y));

    
    vBEZEL_INNER_ZOOM_adapted = get_BEZEL_INNER_ZOOM() * DO_BEZEL;
    //Precalc some Curvature/Warp values:
        float warp_adaption =  1 - vBEZEL_INNER_ZOOM_adapted * 4.0;
        vec2 geom_warp_adapted = vec2(GEOM_WARP_X, GEOM_WARP_Y) * warp_adaption;

        vWarp_vexp = 1.0/ (1 + (vec2(geom_warp_adapted.x, geom_warp_adapted.y) * 0.2)) ;
        vWarp_arg2 = 1.0 - pow(vec2(0.29289321881345247559915563789515), vWarp_vexp );

    //SPOT
        spot_offset = offsets_from_float(S_POSITION+420.0,40);
        spot_offset = spot_offset / 10.0 + vec2(0.0,1.0);
        
    //Help scanline code too:
        if (DO_SCANLINES > 0.5) {
            bool bIs_Interlaced = is_interlaced();
            vIsInterlaced = float(bIs_Interlaced);
            vFlickeringScanlines = float((DO_SCANLINES == 1.0) && scanline_have_to_flicker(bIs_Interlaced)) ;

            //Scanline period:
            vScanlinePeriod = 1.0;
            vScanlinesAlternate = 0.0;
            if (bIs_Interlaced) {
                if (params.FrameCount % 2 == 0.0) vScanlinesAlternate = 1.0;
                if (params.OriginalSize.y > MIN_LINES_INTERLACED )  vScanlinePeriod = 0.5;
            }
            
            //vScanlinePhase = 0.0;
            //vScanlinePhase = vScanlinePeriod * pi - pi/4.0; //<-- needed to match scanlines done in first_pass. //FIXME check what happens for highter res.
        }
}


#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 2) in vec2 spot_offset;
layout(location = 3) in vec2 vFragCoord;
layout(location = 4) in float vIsRotated;
layout(location = 5) in vec2 vWarp_vexp;
layout(location = 6) in vec2 vWarp_arg2;
layout(location = 7) in float vIsInterlaced;
layout(location = 8) in float vFlickeringScanlines;
layout(location = 9) in float vScanlinePeriod;
layout(location = 10) in float vScanlinesAlternate;
layout(location = 11) in float vIn_aspect;
layout(location = 12) in float vBEZEL_INNER_ZOOM_adapted;

layout(location = 0) out vec4 FragColor;



layout(set = 0, binding = 1) uniform sampler2D backdrop;
layout(set = 0, binding = 2)  uniform sampler2D bloom_pass_final;
layout(set = 0, binding = 3)  uniform sampler2D reflected_blurred_pass;
layout(set = 0, binding = 4)  uniform sampler2D ambi_temporal_pass;
layout(set = 0, binding = 5)  uniform sampler2D avglum_pass;
layout(set = 0, binding = 6)  uniform sampler2D monitor_body_straight;
layout(set = 0, binding = 7)  uniform sampler2D monitor_body_curved;
layout(set = 0, binding = 8)  uniform sampler2D bg_under;
layout(set = 0, binding = 9)  uniform sampler2D bg_over;
layout(set = 0, binding = 10) uniform sampler2D shift_and_bleed_pass;
layout(set = 0, binding = 11) uniform sampler2D in_glow_pass;
layout(set = 0, binding = 12) uniform sampler2D halo_pass;



#define RECT01 vec4(0.0, 0.0, 1.0, 1.0)
#define HALF_PI 1.5707963267949
#define QUARTER_PI 0.785398163397448

#include "includes/functions.include.slang"


vec2 vOutputCoord_adapted;
vec2 get_vOutputCoord_adapted() {
    return vOutputCoord_adapted;
}

vec3 pixel_vmask(vec3 source, float white_reference, float over_white) {
    // Simple RGB mask emulation with or without horizontal gap
    float ggg = 1.0 - RGB_MASK_STRENGTH;
    float ooo = max( VMASK_USE_DUMB + 1 - RGB_MASK_STRENGTH, 0.0); //<- make a dumb mask?

    // RGB mask:     R     G     B
    vec3 m1 =  vec3( 1.0 , ooo , ooo );  //col 1
    vec3 m2 =  vec3( ooo , 1.0 , ooo );  //col 2
    vec3 m3 =  vec3( ooo , ooo , 1.0 );  //col 3
    vec3 gap = vec3( ggg );

    vec3 pixel_out;
    vec3 vmasked;
    vec4 vec_mod=(vec4(3,1,2,3) + vec4(VMASK_GAP,0.0,0.0,0.0))* VMASK_DARKLINE_SCALE ;

    float fcol = vOutputCoord.x * params.OutputSize.x;
    float mod_compare = mod(fcol, vec_mod.x);
    
    if (mod_compare < vec_mod.y)
        vmasked = m1;
    else if (mod_compare < vec_mod.z)
        vmasked = m2;
    else if (mod_compare <  vec_mod.w)
        vmasked = m3;
    else vmasked = gap;
    
    vmasked *= source;
    
    //Unbranched previous, worse performance.
        /*
        bool bm1 = (mod_compare < vec_mod.y);
        bool bm2 = (mod_compare < vec_mod.z) && !bm1;
        bool bm3 = (mod_compare < vec_mod.w) && !bm1 && !bm2;
        bool bgap = !bm3 && !bm2 && !bm1;
        vmasked = m1*float(bm1) + m2*float(bm2) + m3*float(bm3) + gap*float(bgap);
        vmasked = source * vmasked;
        */
          
    if (over_white == 1.0) pixel_out = vmasked;
        else {
            white_reference-= over_white;
            white_reference=  clamp(white_reference,0.0,1.0);
            pixel_out=  mix(vmasked,source,white_reference);
        }
   return pixel_out;

}


vec3 pixel_vmask_gm(vec3 source, float white_reference, float over_white) {
    // Simple RGB mask emulation with or without horizontal gap
    float ggg = 1.0 - RGB_MASK_STRENGTH;
    float ooo = max( VMASK_USE_DUMB + 1 - RGB_MASK_STRENGTH, 0.0); //<- make a dumb mask?
    
    // RGB mask:     R     G     B
    vec3 m1 =  vec3( ooo , 1.0 , ooo );    //col 1
    vec3 m2 =  vec3( 1.0 , ooo , 1.0 );    //col 2
    vec3 gap = vec3( ggg );

    float fcol = vOutputCoord.s * params.OutputSize.x;
    vec3 pixel_out;
    vec3 vmasked;
    vec3 vec_mod=(vec3(2,1,2) + vec3(VMASK_GAP,0.0,0.0))* VMASK_DARKLINE_SCALE ;

    float mod_compare = mod(fcol, vec_mod.x);
    
   /* 
    if (mod_compare < vec_mod.y)
        vmasked = m1 * source;
    else if (mod_compare < vec_mod.z)
        vmasked = m2 * source;
    else
        vmasked = gap * source;
    */
   
    //Unbranched previous, same performance.
        bool bm1 = (mod_compare < vec_mod.y);
        bool bm2 = (mod_compare < vec_mod.z) && !bm1;
        bool bgap = !bm2 && !bm1;
        vmasked = m1*float(bm1) + m2*float(bm2) + gap*float(bgap);
        vmasked = source * vmasked;
    
    if (over_white == 1.0) pixel_out = vmasked;
        else {
            white_reference-= over_white;
            white_reference=  clamp(white_reference,0.0,1.0);
            pixel_out=  mix(vmasked,source,white_reference);
        }

   return pixel_out;
}


/*vec3 pixel_vmask_and_gm(vec3 source, float white_reference, float over_white) {
    // Simple RGB mask emulation with or without horizontal gap
    float ooo = 1.0 - RGB_MASK_STRENGTH;

    // RGB mask:     R     G     B
    vec3 m1_rgb =  vec3( 1.0 , ooo , ooo );  //col 1
    vec3 m2_rgb =  vec3( ooo , 1.0 , ooo );  //col 2
    vec3 m3_rgb =  vec3( ooo , ooo , 1.0 );  //col 3
    vec3 gap = vec3( ooo );

    vec3 m1_gm = vec3( ooo , 1.0 , ooo );    //col 1
    vec3 m2_gm = vec3( 1.0 , ooo , 1.0 );    //col 2

    vec3 m1 = (m1_gm * VMASK_USE_GM) + (m1_rgb * (1-VMASK_USE_GM));
    vec3 m2 = (m2_gm * VMASK_USE_GM) + (m2_rgb * (1-VMASK_USE_GM));
    vec3 m3 = m3_rgb;

    vec3 pixel_out;
    vec3 vmasked;
    vec4 vec_mod_rgb = vec4(3,1,2,3);
    vec4 vec_mod_gm =  vec4(2,1,2,0.0);
    vec4 vec_mod = (vec_mod_gm * VMASK_USE_GM) + (vec_mod_rgb* (1-VMASK_USE_GM));
    vec_mod=(vec_mod + vec4(VMASK_GAP,0.0,0.0,0.0))* VMASK_DARKLINE_SCALE ;


    float fcol = vOutputCoord.s * params.OutputSize.x;
    if (mod(fcol, vec_mod.x) < vec_mod.y)
        vmasked = m1 * source;
    else if (mod(fcol, vec_mod.x) < vec_mod.z)
        vmasked = m2 * source;
    else if (    mod(fcol, vec_mod.x) <  vec_mod.w && VMASK_USE_GM < 1.0  )
        vmasked = m3 * source;
    else vmasked = gap * source;

    if (over_white == 1.0) pixel_out = vmasked;
        else {
            white_reference-= over_white;
            white_reference=  clamp(white_reference,0.0,1.0);
            pixel_out=  mix(vmasked,source,white_reference);
        }
   return pixel_out;

}*/


vec3 pixel_darklines(vec3 source,float darkline_every, float darkline_trans,
                     float do_offset, float white_reference,float over_white, vec2 coords) {

    float period_x = (3.0 - VMASK_USE_GM + VMASK_GAP) * VMASK_DARKLINE_SCALE;
    float period_y = darkline_every * VMASK_DARKLINE_SCALE;

    vec2 FragCoord = vFragCoord;

    if (over_white != 1.0) {
        //less effect on bright colors.
        darkline_trans+=(white_reference-over_white);
        darkline_trans=clamp(darkline_trans,0.0,1.0);
    }

    if (do_offset > 0.0) {
        float column = int(floor(mod(FragCoord.x, period_x*2.0)));
        if (column < period_x) FragCoord.y+=period_y/2.0;
    }

    float row = int(floor(mod(FragCoord.y, period_y)));

    if (row < VMASK_DARKLINE_SCALE)
        return source * darkline_trans;
            else
        return source;
}


float scanline_shape(vec2 coords, bool do_slotmask, float lum) {
    /* Produces a B/W scanline shape to be multiplicated by the source
    * pixel later on to emulate scanline effect.
    * scanlines can be drawn on odd and even fields alternating on odd and
    * even frames to emulate that aspect of interlacing.
    */

    float period = vScanlinePeriod;
    bool is_interlaced = bool(vIsInterlaced);
    bool alternate = bool(vScanlinesAlternate);
    bool do_flicker = bool(vFlickeringScanlines);

    //...to scale scanline tickness:
    //float lum_scaled = scale_to_range(lum, SCANLINE_MIN, SCANLINE_MAX);
    float lum_scaled = lum * SCANLINE_MAX;
          lum_scaled = clamp( lum_scaled, SCANLINE_MIN, SCANLINE_MAX );


    float angle_base = coords.y * pi * params.OriginalSize.y * period;// + vScanlinePhase;

    float lines = 1.0;

    if (!( is_interlaced && SCANLINE_DISABLE_ON_INTERLACE == 1.0 )) {

        /*
            if (alternate)
                lines = -sin(angle_base + HALF_PI);
                    else
                lines = sin(angle_base);
        */
        //Unbranched the previous if/then/else:
        lines = (2*vScanlinesAlternate -1) * sin(angle_base + (vScanlinesAlternate * HALF_PI)) ;

        lines = (lines*lines);
    }

    //Draw the slotmask right here if the height is the same as the scanline.
    if (do_slotmask) {
        if (do_flicker) {
            //Fallback to old darklines code to avoid glitches/artifacts.
            lines = lines * pixel_darklines(vec3(1.0),DARKLINES_PERIOD,1-SCANLINE_SM_STRENGTH,1.0, 0.0 ,1.0, coords).r;

        } else {
            float Darkline_part_w = (3.0 - VMASK_USE_GM + VMASK_GAP) * VMASK_DARKLINE_SCALE;
            float Darkline_part_w_x2 = Darkline_part_w*2;
            bool odd_column = mod(vFragCoord.x + Darkline_part_w  , Darkline_part_w_x2) < Darkline_part_w;

            if (SCANLINE_SM_TYPE == 1.0) {
                // Slotmask is out oh phase every "odd" triple and mixed with
                // the straight scanline.
                // slotmask strength and stagger are configurable.
                // Acceptable values are with stagger around 79 (pi/4)
                if (odd_column) {
                    float phase = pi + SCANLINE_SM_VOFFSET*0.01 * lum_scaled;
                    float angle_slotmask = angle_base + phase;
                    float slotmask = sin(angle_slotmask);
                    slotmask = (slotmask*slotmask);
                    lines = mix(lines, slotmask, SCANLINE_SM_STRENGTH);
                }
            }

            else if (SCANLINE_SM_TYPE == 2.0) {
                float phase;
                //Slotmask is always out of phase by QUARTER_PI
                //Every "odd triple" column, it is also out of phase of HALF_PI
                //Slotmask is multiplied by original scanline and thinner.
                //Only strength parameter is taken into account.
               if (odd_column)
                    phase = period * pi + QUARTER_PI * lum_scaled;
                        else
                    phase = period * HALF_PI + QUARTER_PI;

                float angle_slotmask = angle_base + phase;
                float slotmask = sin(angle_slotmask);
                slotmask = slotmask*slotmask; slotmask = slotmask*slotmask; // eleva alla 4 per renderla sottile. valori maggiori producono moiree.
                slotmask = mix(1.0, slotmask, SCANLINE_SM_STRENGTH); // riduci la forza della slotmask
                lines = lines * slotmask;
            }

            else if (SCANLINE_SM_TYPE == 3.0) {
                // Thinner slotmask screen, no scanlines.
                // No parameter taken into account.
                if (odd_column) {
                    float phase = pi + HALF_PI;
                    float angle_slotmask = angle_base + phase;
                    float slotmask = sin(angle_slotmask);
                    slotmask = (slotmask*slotmask); slotmask = (slotmask*slotmask);
                    lines = slotmask;
                }
            }
        }
    }


    //Thickness (min):

        //lines = pow(lines, 1/(lum_scaled+eps) );
        //lines = pow(lines, 1/(sqrt(lum_scaled) ) );
        //lines = pow(lines, 1/(lum_scaled*lum_scaled+eps) );

        //lines = pow( lines , 1/(lum_scaled ) ) ;

        //0.0125 is an anti-moiree measure.

        //lines = pow(   max(lines, 0.05),   1/lum_scaled) ;

        //lines = pow(lines, 1/(sqrt(lum_scaled) ) );

        //lines = pow(clamp(lines + 0.05, 0.0,1.0) , 1/sqrt(lum_scaled));
        //float extra_power_1 = 3.0;

        

        
        float extra_power_1 = max(SCANLINE_MAX/3.0, 1.0);

        lines = pow(clamp(lines, SCANLINE_DARK * 2.0, 1.0) , 1/(sqrt(lum_scaled*lum_scaled*extra_power_1) ) );

        //lines = pow(clamp(lines + 0.05, 0.0,1.0) , 1/(sqrt(lum_scaled*lum_scaled*extra_power_1) ) ) * extra_power_1/2.0;


        //lines = pow(clamp(lines + 0.05, 0.0,1.0) , 1/(lum_scaled*lum_scaled));

        //Thickness (max):

            /*lines = pow(abs(lines), 1/(10*lum_scaled*lum_scaled));
            float clamp_start=0.5;
            if (lum_scaled>clamp_start) lines = clamp(lines,(lum_scaled-clamp_start)/(1-clamp_start) ,1.0); //FIXME use step?*/

    //min-max, ma difficile da gestire con la slotmask.
    //    float extra_power = 2.0;
    //    float m = mod(angle_base + (vScanlinesAlternate * HALF_PI), pi);
    //    lines = exp( -pow((m-(HALF_PI)),2) / ( lum*extra_power ) ) * extra_power;


    lines = lines * (1-SCANLINE_DARK ) + SCANLINE_DARK ;
    return lines;
}

float get_clamped_white_reference(vec3 pixel_in){
    float white_reference = max(max(pixel_in.r,pixel_in.g),pixel_in.b);
    white_reference = min(white_reference,1.0); //Clamp here for both vmask and darklines.
    return white_reference;
}


float global_noise = 0.0;


vec3 pixel_backdrop_image() {
    vec2 backdrop_offset=vec2(BACKDROP_OFFX,BACKDROP_OFFY);

    vec2 backdrop_tex_size = textureSize(backdrop, 0);
    float backdrop_lod = log2(backdrop_tex_size.y / global.FinalViewportSize.y);

    vec2 backdrop_coords =  get_scaled_coords_aspect(
                            vOutputCoord+backdrop_offset,
                            global.FinalViewportSize,
                            backdrop_tex_size.x/backdrop_tex_size.y,
                            bool(vIsRotated));

    backdrop_coords=zoom(backdrop_coords, BACKDROP_ZOOM);
    return textureLod(backdrop, backdrop_coords, backdrop_lod).rgb;
}


vec4 textureLod_wrap(sampler2D tex, vec2 co, float lod, float wrap_mode) {
    #ifdef ALLOW_BG_IMAGE_TEXTURE_WRAP_IN_SHADER
        /*
        // Mirrored repeat, once, useless since is done by default
        if (co.x > 1.0 || co.x < 0.0)
            co.x = 1- mod(co.x, 1.0);
        if (co.y > 1.0 || co.y < 0.0)
            co.y = 1- mod(co.y, 1.0);
        */

        if (wrap_mode == 1.0) {
            //Clamp to border, black.
            bool bOutside = (co.x < 0.0 || co.x > 1.0 || co.y < 0.0 || co.y > 1.0 ) ;
            if (bOutside) return vec4(0.0,0.0,0.0,1.0);
        } else if (wrap_mode == 2.0) {
            //Clamp to edge:
            co = clamp(co, 0.00, 1.0);
        } else if (wrap_mode == 3.0) {
            //Repeat no mirror:
            co = mod(co, 1.0);
        }
    #endif
    return textureLod(tex, co, lod);
}


vec3 pixel_alternate(vec3 source, float whiteness) {
    // Emulate the low crt persistance by only drawing odd/even lines
    // on odd/even frames
    float line = vTexCoord.y * params.OutputSize.y;
    vec3 pixel_out = source;
    float l_period_half = ALT_BLANK_PERIOD / 2;
    if  (mod(float(params.FrameCount),2.0  ) == 1) {
        if  (mod(line,ALT_BLANK_PERIOD) > l_period_half) pixel_out=mix(source,vec3(0), whiteness) ;
    } else {
        if  (mod(line,ALT_BLANK_PERIOD) <= l_period_half) pixel_out=mix(source,vec3(0), whiteness) ;
    }
    return pixel_out;
}


vec3 bezel_color(float lum)  {
    //Colorize bezel frame
    vec3 col = vec3(BEZEL_R,BEZEL_G,BEZEL_B) + lum;
    float con_max =  0.5 * BEZEL_CON + 0.5;
    col = scale_to_range_vec3(col, -con_max+1, con_max);
    return clamp(col,0.0,1.0);
}


float fuzzyrect(vec2 uv, vec2 size, float radius, float blur) {
    vec2 hSize = size / 2.0 - radius;
    float d = length(max(abs(uv - vec2(0.5)),hSize)-hSize);
    return smoothstep(-radius-blur, -radius+blur, -d);
}

float create_ambi_colorize_shade(vec2 co) {
    float blur = AMBI_OVER_BEZEL_SIZE;
    vec2 size = vec2(1.0, 2 - AMBI_OVER_BEZEL_AR_CORRECTION)-blur;
    float radius = 0.0;

    return  1 - min ( fuzzyrect(co, size,  radius,  blur) * 2, 1.0);
}
    


vec2 get_scaled_coords_for_bezel() {
    //This function is here because compiler gets mad if i calc coords_for_bezel
    //outside the main branch "if DO_BEZEL then compose_bezel_over"
    //performances falls down for no apparent reason.
    //But still, i need to access it twice in the code.
    //So this is a function that ensures me that i always calc it the same way.
    
    vec2 co = zoomout_coords(vTexCoord,-BEZEL_FRAME_ZOOM,1.0);
    
    if (DO_TILT == 1.0) 
        return tilt(co, vIsRotated, TILT_X, TILT_Y, TILT_BEZEL_K);
            else
        return co;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////

vec4 fn_pixel_bg_image() {
    vec2 bg_image_offset = vec2(BG_IMAGE_OFFX, BG_IMAGE_OFFY);
    vec2 tex_size = textureSize(bg_under, 0); // * BG_ZOOM;
    vec2 co_bg_image = get_scaled_coords_aspect(vOutputCoord + bg_image_offset, global.FinalViewportSize, tex_size.x/tex_size.y, bool(vIsRotated));
    float bg_image_lod = log2(tex_size.y / global.FinalViewportSize.y);
    
    if (BG_IMAGE_ROTATION > 0.0) {
        co_bg_image.xy = co_bg_image.yx;
        if (BG_IMAGE_ROTATION == 1.0) co_bg_image.y = 1 - co_bg_image.y;
        if (BG_IMAGE_ROTATION == 2.0) co_bg_image.x = 1 - co_bg_image.x;
    }
    co_bg_image = zoom(co_bg_image, BG_IMAGE_ZOOM);
    return textureLod_wrap(bg_under, co_bg_image, bg_image_lod, BG_IMAGE_WRAP_MODE);
    return vec4(0.0);
}

vec4 fn_pixel_fg_image() {
    vec2 fg_image_offset=vec2(BG_IMAGE_OFFX,BG_IMAGE_OFFY);
    vec2 tex_size = textureSize(bg_over, 0); // * BG_ZOOM;
    float bg_over_lod = log2(tex_size.y / global.FinalViewportSize.y);

    if (BG_IMAGE_ROTATION > 0.0  || ( BG_IMAGE_ROTATION < 0.0 && bool(vIsRotated) )  ) tex_size.xy = tex_size.yx;

    vec2 back_coords = get_scaled_coords_aspect(vOutputCoord + fg_image_offset, global.FinalViewportSize, tex_size.x/tex_size.y, bool(vIsRotated));

    if (BG_IMAGE_ROTATION < 0.0 && bool(vIsRotated) ) {
        //handle automatic rotation of bg image for rotated games
        back_coords.xy = back_coords.yx;
        back_coords.y = 1 - back_coords.y;
    } else if (BG_IMAGE_ROTATION > 0.0) {
        //rotate as user prefs
        back_coords.xy = back_coords.yx;
        if (BG_IMAGE_ROTATION == 1.0) back_coords.y = 1 - back_coords.y;
        if (BG_IMAGE_ROTATION == 2.0) back_coords.x = 1 - back_coords.x;
    }
    back_coords=zoom(back_coords, BG_IMAGE_ZOOM);
    vec4 pixel_bgover = textureLod_wrap(bg_over, back_coords, bg_over_lod, BG_IMAGE_WRAP_MODE);
    return pixel_bgover;
}

vec3 ambi_blend_image(vec4 image, vec3 ambi) {
    //mix or add ambient light with image, also allow force colorization in add mode.
    if (DO_AMBILIGHT == 0.0) return image.rgb;
        
    image.rgb = (AMBI_BG_IMAGE_BLEND_MODE == 0.0) ? 
        mix(ambi.rgb, image.rgb, image.a) 
            : 
        image.rgb + (ambi.rgb * (1 - image.a)); 
        
    return image.rgb;
}


vec3 fn_pixel_content(vec2 coords) {
    vec3 pixel_in;
    vec3 pixel_glowed;
    vec3 pixel_bleed; //pixel_bleed is the color that will bleed over scanline gap
    
    if  (DO_IN_GLOW == 1.0) {
        pixel_glowed = texture(in_glow_pass,coords).rgb;
        pixel_in = pixel_glowed;
    } else {
        pixel_in = texture(shift_and_bleed_pass,coords).rgb ;
    }
    pixel_bleed = pixel_in;
    
    vec3 pixel_out = pixel_in;
    float white_reference;
    
    if (VMASK_OVERWHITE+DRKLN_OVERWHITE  < 2.0 ) {
        white_reference = get_clamped_white_reference(pixel_in);
    }

    //Mask and darklines:
        if (DO_VMASK_AND_DARKLINES == 1.0 ) {
            vec3 pixel_in_compensated = pixel_in;

            pixel_in_compensated = pixel_push_luminance(pixel_in, RGB_MASK_STRENGTH * MASK_COMPENSATION);

            if (RGB_MASK_STRENGTH > 0.0) {
                //Use RGB pattern or exploit RGB layout with green and magenta?
                if (VMASK_USE_GM < 1.0)
                    pixel_out = pixel_vmask(pixel_in_compensated, white_reference, VMASK_OVERWHITE);
                else
                    pixel_out = pixel_vmask_gm(pixel_in_compensated, white_reference, VMASK_OVERWHITE);
                //Tried to unbranch to no avail (worse performances)
                //pixel_out = pixel_vmask_and_gm(pixel_in_compensated, white_reference, VMASK_OVERWHITE);
            }

            pixel_out = pixel_push_luminance(pixel_out, DARKLINES_STRENGTH * (1.0/DARKLINES_PERIOD) * MASK_COMPENSATION);

            //Screen lines (slotmask aperture grille)
            if (   DARKLINES_STRENGTH > 0.0 ) {
                float MYDARKLINES_TRANSPARENCY = 1.0 - DARKLINES_STRENGTH;
                pixel_out = pixel_darklines(pixel_out, DARKLINES_PERIOD, MYDARKLINES_TRANSPARENCY, DARKLINES_VOFFSET, white_reference, DRKLN_OVERWHITE, coords);
            }

        }

    //Halo
        vec3 pixel_haloed = vec3(0.0);;
        if (DO_HALO == 1.0 ) {
            pixel_haloed = texture(halo_pass,coords).rgb;
            pixel_out += pixel_haloed * (1 - HALO_VS_SCAN);
        }

    //Scanlines (non-flickering)
        if  ( DO_SCANLINES == 1.0 ) {
            // Optionally apply a gamma correction to the scanline shape.
                if (SCANLINE_COMPENSATION > 0.0) {
                    float mypow = mix(1.0, (0.33 * SCANLINE_DARK + 0.67), SCANLINE_COMPENSATION);
                    pixel_out = pow(pixel_out,vec3(mypow));
                }

            //Obtain the scanlines screen by multiplying the scanline shape by the pixel color.
            //and emulate the bleeding of the color over the dark part of the scanlined screen.
            //float scanline_shape = scanline_shape(coords, SCANLINE_SM_TYPE > 0.0 );
                float lum = max(max(pixel_out.r, pixel_out.g), pixel_out.b);
                float scanline_shape = scanline_shape(coords, SCANLINE_SM_TYPE > 0.0, lum );
                pixel_out = pixel_out * ( scanline_shape + ( pixel_bleed * SCANLINES_BLEEDING * ( 1 - scanline_shape ) ));
        }

    //Add the remaining halo to the scanline gap
        pixel_out += pixel_haloed * HALO_VS_SCAN;

    // Apply gamma out:
        if (DO_CCORRECTION == 1.0) 
            pixel_out = pow(max(pixel_out, vec3(0.0)),vec3(GAMMA_OUT));

    //Bloom
        if (DO_BLOOM == 1.0 ) {
            vec3 bloomed=texture(bloom_pass_final, coords).rgb ;
            pixel_out = bloomed + float(BLOOM_BYPASS < 0.5) * pixel_out;
        }
        
    //Black frame insertion, made static, enable it in config.inc.
        #ifdef ALLOW_ALT_BLANK
            if (DO_ALT_BLANK == 1.0 ) {
                pixel_out.rgb = pixel_alternate(pixel_out.rgb, ALT_BLANK_STRENGTH );
            }
        #endif
        
    //Vignette
        if (DO_VIGNETTE == 1.0) {
            float dist = length(vec2((coords.x-0.5)*vIn_aspect, coords.y-0.5));
            float vignette = smoothstep(V_SIZE,0.0,dist)*V_POWER;
            pixel_out = pixel_out * vignette + global_noise;
        }
        
    //Spot
        if (DO_SPOT == 1.0) {
                float dist = length(vec2((coords.x-0.5)*vIn_aspect, coords.y-0.5)+spot_offset);
                float spot = smoothstep(S_SIZE,0.0,dist)*S_POWER;
                pixel_out = pixel_out + spot + (global_noise* (1 - DO_VIGNETTE));
        }
    
    
    return pixel_out;
}


vec4 fn_pixel_bezel(vec2 coords_for_bezel, vec2 coords_for_mirror) {
    
    //Can we skip Blank outside border and inner blank tube?
        vec4 inner_blank_rect = vec4(1-BEZEL_TUBE_BLANK_SIZE, 1-BEZEL_TUBE_BLANK_SIZE, BEZEL_TUBE_BLANK_SIZE, BEZEL_TUBE_BLANK_SIZE);
        if (is_first_outside_rect(coords_for_bezel, RECT01)  ||
            is_first_inside_rect(coords_for_bezel, inner_blank_rect)
        ) return vec4(0.0);

    vec4 bezel_in;    
    //Sample main bezel texture, Do we want mipmaps?
        #ifdef STATIC_BEZEL_USE_MIPMAP
            vec2 bezel_lut_size = textureSize(monitor_body_curved,0); //no need to branch here if we assume straight and curved textures are the same size. //FIXME?
            float bezel_frame_lod = log2(bezel_lut_size.y * (BEZEL_FRAME_ZOOM+1.0) /global.FinalViewportSize.y);
            if (BEZEL_USE_STRAIGHT < 0.5)
                bezel_in = textureLod(monitor_body_curved,coords_for_bezel,bezel_frame_lod);
                    else
                bezel_in = textureLod(monitor_body_straight,coords_for_bezel,bezel_frame_lod);
        #else
            if (BEZEL_USE_STRAIGHT < 0.5)
                bezel_in = texture(monitor_body_curved,coords_for_bezel);
                    else
                bezel_in = texture(monitor_body_straight,coords_for_bezel);
        #endif
    

    //Exit if the bezel is completely transparent (the tube)
        if (bezel_in.a == 0.0) return vec4(0.0);
        
    //Colorize the bezel (bezel.r expresses the luminance)
        vec3 bezel_out = bezel_color(bezel_in.r);
    
    float lut_specular = bezel_in.g * BEZEL_SPCL_STRENGTH;
    float reflection_modifier = 0.0;

    //Reflections, can be skipped if blue channel is 0:
        if (bezel_in.b > 0.0) {
        //Reflections: Calculate the bezel roughness to apply to the reflecting area. (bezel_in.g expresses the specularity)
            float roughness = random( min(global.FinalViewportSize.z,global.FinalViewportSize.w) * BEZEL_ROUGHNESS, vTexCoord );
            roughness *=  (1 - min(lut_specular * 10, 1.0)); // <-roughness over specular area looks bad.
            
        //Reflections:
            reflection_modifier = bezel_in.b * BEZEL_REFL_STRENGTH; //bezel_in.b expresses how much the area is reflective
            
            //Sample the reflection pass with small offset to simulate the roughness
                vec3 pixel_mirrored = texture(reflected_blurred_pass, coords_for_mirror + roughness).rgb; 
                float fcorners_shade = corners_shade(coords_for_bezel, 1.0);
                pixel_mirrored*=1-(fcorners_shade);
                
            //Push it over the specular areas and apply the reflection modifier
                pixel_mirrored = pixel_mirrored * (1 + lut_specular) * reflection_modifier;

            //Apply reflections
                bezel_out += pixel_mirrored;
        }

    //Mix ambient light over bezel? (branching this is worse)
        vec3 ambitemporalpass = texture(ambi_temporal_pass, vOutputCoord ).rgb;
        ambitemporalpass = max(ambitemporalpass, 0.0); //<-- antiglitch. Needed to avoid undefined variable on vulkan.
        vec3 pixel_ambilight = DO_AMBILIGHT * ( ambitemporalpass + global_noise * NOISEPOWER_AMBI_MUL);
            
        //Create a shaded box to apply ambilight on external borders only
            float ambi_colorize_shade = create_ambi_colorize_shade(coords_for_bezel);
            bezel_out = bezel_out +  (AMBI_OVER_BEZEL * pixel_ambilight * bezel_in.a * ambi_colorize_shade * (1-reflection_modifier));
        
    //Diffuse the light over specular areas, we use a mipmap with low precision.
        if (lut_specular > 0.0) {
            vec4 pixel_avglum = texture(avglum_pass, coords_for_mirror);
            bezel_out = bezel_out + (pixel_avglum.rgb * lut_specular) ;
        }

    return vec4(bezel_out, bezel_in.a);
}


void main() {
    vec3 pixel_out = vec3(0.0);
    
    float canvas_busy = 0.0; //<-- this allow for paint over not painted areas (spares gpu cycles)

    //Calc a random noise if we need debanding
        if (DO_VIGNETTE + DO_SPOT + DO_AMBILIGHT >0.0)
            global_noise = random(NOISEPOWER, vTexCoord * params.FrameCount);
    
    //Calc initial content coords
        vec2 co_content = vTexCoord;
        if (DO_CURVATURE == 1.0  &&  ((GEOM_WARP_X != 0.0) || (GEOM_WARP_Y != 0.0))) {
            co_content = Warp_fast(co_content, vWarp_vexp, vWarp_arg2, GEOM_CUT_EARS);
            //co_content = Warp(co_content, GEOM_WARP_X, GEOM_WARP_Y);
        }

    //Tilt?
        if (DO_TILT == 1.0)
            co_content = tilt(co_content, vIsRotated, TILT_X, TILT_Y, 1.0);


    //Precalc Bezel coords, since it modifies content coords.
        vec2 co_bezel = vec2(0.0);
        vec2 co_mirror;
        if (DO_BEZEL == 1.0) {
            co_content = zoomout_coords(co_content, -vBEZEL_INNER_ZOOM_adapted , 1.0);
            co_mirror = zoom(co_content, 1/BEZEL_REFL_ZOOMOUT_ROOM);
            co_bezel = get_scaled_coords_for_bezel();
        }

        
    //Apply other content coords modifiers
        if (DO_GAME_GEOM_OVERRIDE == 1.0)
            co_content = content_geom_override(co_content, GAME_GEOM_ASPECT, vIn_aspect, GAME_GEOM_VSHIFT, GAME_GEOM_HSHIFT, GAME_GEOM_ZOOM);

        if (DO_DYNZOOM == 1.0)
            co_content = zoom(co_content, get_dyn_zoom(avglum_pass) );

    
    //Create an alpha mask to write content into, it holds opacity info that will be used to compose.:
        if (DO_CURVATURE == 1.0)  {
            canvas_busy = fn_border(co_content);
        } else {
            canvas_busy = float(is_first_inside_rect(co_content, RECT01)); //FIXME: is step() faster?
        }

        
    //Draw content only over the alpha mask, spare gpu cycles.
        if (canvas_busy > 0.0)
            pixel_out = fn_pixel_content(co_content);
              
    //Backdrop
        if (DO_BACKDROP == 1.0)
            pixel_out += pixel_backdrop_image();

    //Draw Bezel
        vec4 pixel_bezel;
        //SKIP LOGIC is inside fn_pixel_bezel
        if (DO_BEZEL == 1.0) {
            pixel_bezel = fn_pixel_bezel(co_bezel, co_mirror);
            //If we used a smooth_border, canvas_busy is it, but since the content is in the bezel,
            //we can safely use it to smooth/darken the game border
            pixel_out *= canvas_busy; 
            pixel_out = mix(pixel_out, pixel_bezel.rgb, pixel_bezel.a);
            
            //Update alpha mask.
            //We can't use the bezel alpha channel to update the alpha mask since it is transparent ù
            //on the tube and we don't want to paint anything there, so use a dumb rect and add it to canvas_busy:
                float rect_bezel = float(is_first_inside_rect(co_bezel, vec4(BEZEL_SHADOW_SIZE, BEZEL_SHADOW_SIZE, 1.0 - BEZEL_SHADOW_SIZE, 1.0 - BEZEL_SHADOW_SIZE)));
                canvas_busy = max(pixel_bezel.a, rect_bezel);
                //FragColor = vec4(canvas_busy); return; // <- uncomment to debug BEZEL_SHADOW_SIZE
        }

    //The following funcs have to paint in the outer border
        vec3 pixel_ambi = vec3(0.0);
        vec3 pixel_under_content = vec3(0.0);
        if ( canvas_busy < 1.0) {

            //Ambient light
                if (DO_AMBILIGHT == 1.0) {
                    vec2 co_ambi = vOutputCoord;
                    pixel_ambi = texture(ambi_temporal_pass, co_ambi).rgb + global_noise * NOISEPOWER_AMBI_MUL;
                    pixel_under_content = pixel_ambi;
                }
            
            //Background image:
                if (DO_BG_IMAGE == 1.0 && BG_IMAGE_OVER == 0.0) {
                    vec4 pixel_bg_image = fn_pixel_bg_image();
                    pixel_bg_image.rgb = ambi_blend_image(pixel_bg_image, pixel_ambi);        
                    pixel_under_content = pixel_bg_image.rgb;
                }
            
        }

        //Smooth the image corners: canvas_busy (the alpha mask) is a white rect with shaded borders.
            pixel_out = mix (pixel_under_content, pixel_out, canvas_busy);
 
          
        //Foreground image
            if (DO_BG_IMAGE + BG_IMAGE_OVER == 2.0) {
                vec4 pixel_fg_image = fn_pixel_fg_image();
                pixel_out = mix(pixel_out, pixel_fg_image.rgb, pixel_fg_image.a);
                
                if (DO_AMBILIGHT + AMBI_BG_IMAGE_BLEND_MODE == 2.0) { 
                    vec3 pixel_ambi_local = texture(ambi_temporal_pass, vOutputCoord ).rgb;
                    pixel_ambi_local = DO_AMBILIGHT * (pixel_ambi_local + global_noise * NOISEPOWER_AMBI_MUL);
                    pixel_ambi_local = max(pixel_ambi_local, 0.0); //<-- antiglitch. Needed to avoid undefined variable on vulkan.
                    float ambi_mask = create_ambi_colorize_shade(co_bezel);
                    float fg_image_alpha_adapted = max(pixel_fg_image.a - AMBI_BG_IMAGE_FORCE, 0.0);
                    pixel_out = pixel_out + (pixel_ambi_local.rgb * (ambi_mask) * (1- fg_image_alpha_adapted));
                }
            }
  
     
        
    FragColor = vec4(pixel_out, 1.0);
   
}

