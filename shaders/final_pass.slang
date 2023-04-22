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
layout(location = 3) out vec2 vFragCoord_Tated;
layout(location = 4) out float vIsRotated;


//Curvature:
    layout(location = 5) out vec2 vWarp_vexp;
    layout(location = 6) out vec2 vWarp_arg2;

//Scanlines:
    layout(location = 7) out float vIsInterlaced;
    layout(location = 8) out float vFlickeringScanlines;
    layout(location = 9) out float vScanlinePeriod;
    layout(location = 10) out float vScanlineAlternateOffset;
    layout(location = 11) out float vMax_inLum;
    
//Vignette, spot:
    layout(location = 12) out float vIn_aspect;
    
layout(location = 13) out float vDynamicSeed;
layout(location = 14) out float vBEZEL_INNER_ZOOM_adapted;
layout(location = 15) out float vVmask_gap;
layout(location = 16) out float vFcol_Tated;
layout(location = 17) out float vDo_Tate;
layout(location = 18) out vec3 vDotMat_Grid_Color;

#include "includes/functions.include.slang"

#define PI_15 4.71238898038469 //pi*1.5

void main() {
    gl_Position = global.MVP * Position;
    vIsRotated = float(is_rotated());
    vIn_aspect = get_in_aspect();
    
    //Calculate vTexcoord as fractional or integer scaled?
        if ( need_NO_integer_scale() )
            vTexCoord = get_scaled_coords_aspect(TexCoord,global.FinalViewportSize, vIn_aspect, bool(vIsRotated)) + vec2(0.0000);
                else
            vTexCoord = integer_scale(TexCoord, vIn_aspect, bool(vIsRotated), GAME_GEOM_INT_SCALE-1.0 ) + vec2(0.0001); //<- without the offset, SCANLINE_MIN doesn't work.

    //if (DO_GLOBAL_SHZO >0.5)
    //    vTexCoord = zoom(vTexCoord + vec2(-GLOBAL_OFFX, -GLOBAL_OFFY), GLOBAL_ZOOM );
    //..unbranched previous
        vTexCoord = (zoom(vTexCoord + vec2(-GLOBAL_OFFX, -GLOBAL_OFFY), GLOBAL_ZOOM ) * DO_GLOBAL_SHZO) + 
                    (vTexCoord * (1-DO_GLOBAL_SHZO) );

    vOutputCoord = TexCoord;


    vec2 vFragCoord = vec2( floor(vOutputCoord.x * params.OutputSize.x),
                       floor(vOutputCoord.y * params.OutputSize.y));

    vDo_Tate = float(TATE+vIsRotated > 1.001);
    vFragCoord_Tated = mix_step(vFragCoord.xy, vFragCoord.yx, vDo_Tate );

    vBEZEL_INNER_ZOOM_adapted = get_BEZEL_INNER_ZOOM() * DO_BEZEL;
    
    //Precalc some Curvature/Warp values:
        vWarp_vexp = 1.0/ (1 + (vec2(GEOM_WARP_X, GEOM_WARP_Y) * 0.2)) ;
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
            vScanlineAlternateOffset = 0.0;
            
            if (bIs_Interlaced) {
                if (params.FrameCount % 2 == 0.0) vScanlineAlternateOffset = PI_15;
                vScanlinePeriod = 0.5;
            }
            
            //Calculate the maximum possible brightness of the input color by taking glow,
            //contrast and brightness into account. This is needed so that scanline generation
            //can map the proper input range and strictly obey scanline thickness constraints.
                vMax_inLum = max( 1.0, DO_CCORRECTION * apply_contrast_brightness(1.0, CONTRAST, BRIGHTNESS)) *
                             max( 1.0, DO_IN_GLOW * IN_GLOW_POWER);
        }
        
        //Generate a seed that changes over time for temporal random noise
            vDynamicSeed = mod(params.FrameCount, 60.0001);
        
        //slotmask/vmask gap size:
            //Gap size in pixel for 1X to 4X mask scaling:
            // vec4 GAP_SIZE_PER_SCALE = vec4(1.0, 1.0, 2.0, 2.0);  <--- moved in config.inc
            vec4 vgap_size_per_scale = GAP_SIZE_PER_SCALE / VMASK_DARKLINE_SCALE;
            vVmask_gap = vgap_size_per_scale[int(VMASK_DARKLINE_SCALE-1)];

            vFcol_Tated = mix_step(vOutputCoord.x * params.OutputSize.x, vOutputCoord.y * params.OutputSize.y, vDo_Tate);

        //Calc dotmat grid color
            vDotMat_Grid_Color = vec3(DOT_M_G_BRT);
            if (DO_DOT_MATRIX + DO_CCORRECTION > 1.1) {
                vDotMat_Grid_Color = color_tools(vec3(DOT_M_G_BRT), kelvin2rgb(TEMPERATURE));
                //Since we modify grid brightness via a specific use parameter, explicitely multiply it by that:
                    vDotMat_Grid_Color *= DOT_M_G_BRT ;
            }
}


#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 2) in vec2 spot_offset;
layout(location = 3) in vec2 vFragCoord_Tated;
layout(location = 4) in float vIsRotated;
layout(location = 5) in vec2 vWarp_vexp;
layout(location = 6) in vec2 vWarp_arg2;
layout(location = 7) in float vIsInterlaced;
layout(location = 8) in float vFlickeringScanlines;
layout(location = 9) in float vScanlinePeriod;
layout(location = 10) in float vScanlineAlternateOffset;
layout(location = 11) in float vMax_inLum;
layout(location = 12) in float vIn_aspect;
layout(location = 13) in float vDynamicSeed;
layout(location = 14) in float vBEZEL_INNER_ZOOM_adapted;
layout(location = 15) in float vVmask_gap;
layout(location = 16) in float vFcol_Tated;
layout(location = 17) in float vDo_Tate;
layout(location = 18) in vec3 vDotMat_Grid_Color;

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


layout(set = 0, binding = 15) uniform sampler2D flick_and_noise_pass;



#define RECT01 vec4(0.0, 0.0, 1.0, 1.0)
#define HALF_PI 1.5707963267949
#define QUARTER_PI 0.785398163397448

#include "includes/functions.include.slang"


vec2 vOutputCoord_adapted;
vec2 get_vOutputCoord_adapted() {
    return vOutputCoord_adapted;
}


vec3 fn_pixel_nightify(vec3 color_in, float strength) {
    if (strength == 0.0) return color_in;
    
    color_in = clamp(color_in, 0.0, 1.0);
    
    vec3 color_hsv_in = rgb2hsv(color_in);
    strength = scale_to_range(strength, 0.0, 1.0); 
    
    vec3 color_hsv_min = color_hsv_in;
    color_hsv_min.yz = scale_to_range_vec2(color_hsv_min.yz, -0.1, 0.1); 

    vec3 color_rgb_min = hsv2rgb(color_hsv_min);
    return mix(color_in, color_rgb_min, strength);
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

    vec4 vec_mod=(vec4(3,1,2,3) + vec4(VMASK_GAP * vVmask_gap,0.0,0.0,0.0))* VMASK_DARKLINE_SCALE;
    vec_mod = ceil(vec_mod);
    

    float mod_compare = mod(vFcol_Tated, vec_mod.x);
    
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

    vec3 pixel_out;
    vec3 vmasked;
    vec3 vec_mod=(vec3(2,1,2) + vec3(VMASK_GAP * vVmask_gap,0.0,0.0))* VMASK_DARKLINE_SCALE ;
    vec_mod = ceil(vec_mod);
    
    float mod_compare = mod(vFcol_Tated, vec_mod.x);
    
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


vec3 pixel_darklines(vec3 source,float darkline_every, float darkline_trans,
                     float do_offset, float white_reference,float over_white, vec2 coords) {

    float period_x = (3.0 - VMASK_USE_GM + VMASK_GAP * vVmask_gap) * VMASK_DARKLINE_SCALE;
    float period_y = darkline_every * VMASK_DARKLINE_SCALE;

    vec2 FragCoord = vFragCoord_Tated;

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

    if (row < VMASK_DARKLINE_SCALE * vVmask_gap)
        return source * darkline_trans;
            else
        return source;
}



vec4 fn_pixel_dotmat(vec2 coords, vec3 pixel_in) {
  
       
    //Base angle, depends on original size:
        vec2 angle_base = coords * pi * params.OriginalSize.xy; //FIXME here we want .yy to make integer scaling

    //Zoom to debug:
        angle_base/=DOT_M_MULTIPLY;

    //Set the rgb and grid sharpness:
        vec3 s_rgb = vec3(DOT_M_RGB_SHARP);
        float s_grid = DOT_M_G_SHARP;
        
    //Generate bw grid:     
        vec2 grid = cos(angle_base);
        grid = grid * grid;
        grid = pow(grid, vec2(s_grid));
        grid = 1 - grid;

    //Generate rgb mask 
    vec3 mask_rgb=vec3(1.0);
    if (DOT_M_RGB_STR > 0.0) {
        //float wideness_k = DOT_M_RGB_WID;
        float rgb_wideness = (pi/4.0); // * wideness_k;
        
        //Generates 3 sines with 1/3 pi offset
            vec3 angle_rgb = vec3( angle_base.x + rgb_wideness,
                                   angle_base.x - pi,
                                   angle_base.x - rgb_wideness );
        
            mask_rgb = sin(angle_rgb);
            mask_rgb *= mask_rgb;
            mask_rgb = pow(mask_rgb, s_rgb);
            
        //Adjust green gain
            mask_rgb.g *= DOT_M_G_GAIN;
            
        //Apply strength
            mask_rgb=mix(vec3(1.0), mask_rgb, DOT_M_RGB_STR);
    }
    

    //Combine gridx and gridy into a single one
        //float fgrid = min(grid.x, grid.y);
        float fgrid = grid.x* grid.y;

    //Modify strength for "paint on background" option

        //Smoothly fadeout grid on background
            //The fadeout size:
                float fade_size = 0.3;
            
            //We invert the smooth logic if threshold is negative. this allow to fadeout
            //the grid on bright or dark backgrounds.
                float lum_scaled = dot(pixel_in, vec3(0.33333));
                lum_scaled = clamp(lum_scaled, 0.0, 1.0);
                lum_scaled = mix_step(1-lum_scaled, lum_scaled, float(DOT_M_G_TRESH > 0.0));
                
            float smooth_threshold = abs(DOT_M_G_TRESH);
            vec2 smooth_range  = vec2(smooth_threshold, smooth_threshold+fade_size);
            float grid_smoothstep = 1- smoothstep(smooth_range.x, smooth_range.y, lum_scaled);    


            
    //Adapt grid strength
        float grid_str = DOT_M_G_STR * grid_smoothstep;    
    //Apply strength modifier
        float fgrid_adpt = mix(1.0, fgrid, grid_str);
    

    //Output is the mix of the gap and the rgb masked pixel in.
    //In the alpha channel we put the grid because it could be selectiveli brightened by halo
    return vec4( 
                 mix(vDotMat_Grid_Color, pixel_in * mask_rgb ,fgrid_adpt),
                 fgrid_adpt
               );

}

float fn_scanline_mask(vec2 coords, bool do_slotmask, float lum, float min_inLum, float max_inLum, float tate) {
    /* Produces a B/W scanline shape to be multiplicated by the source
    * pixel later on to emulate scanline effect.
    * scanlines can be drawn on odd and even fields alternating on odd and
    * even frames to emulate that aspect of interlacing.
    */

    float period = vScanlinePeriod;
    bool is_interlaced = bool(vIsInterlaced);
    bool do_flicker = bool(vFlickeringScanlines);
    
    //since luminosity is used to modulate scanline thickness, we scale it here
    //to keep tickness in user defined range:
        float lum_scaled = map_range(lum, min_inLum, max_inLum, SCANLINE_MIN, SCANLINE_MAX);

    
    float lines = 1.0;

    //0 - Generate base scanline.
    //1 - The base coords is switched from coords.y to coords.x if tate mode is requested.
    //2 - offset them on odd frames if needed (vScanlineAlternateOffset via vertex shader)
    //3 - Dont do it when the screen is interlaced and we have to skip drawing scanlines on interlaced screens

        //coords += params.OriginalSize.zw*0.5; //<-- this seems needed when using integer scaling
        //due to linear filtering in earlier pass FIXME don't forget me!
        coords = mix_step(coords.xy, coords.yx, tate);
        float originalsize = mix_step(params.OriginalSize.y, params.OriginalSize.x, tate);

        float angle_base = coords.y * pi * originalsize * period;


        if  (!( is_interlaced && SCANLINE_DISABLE_ON_INTERLACE == 1.0 )) {
            lines = pow( sin(angle_base + vScanlineAlternateOffset), 2.0);
        }

    //If we specified to draw slotmasks alongside the scanlines, but the screen
    //is interlaced, fallback to old darklines code to avoid glitches/artifacts.
        if ( do_slotmask && is_interlaced ) {
            lines = lines * pixel_darklines(vec3(1.0),DARKLINES_PERIOD,1-SCANLINE_SM_STRENGTH, 1.0, 0.0 , 1.0, coords).r;
            return lines;
        }
    
    //Draw a sort of slotmask right here with the same height as the scanline.
    //Mitigates moiree and visual artifacts comapred to dumb viewport slotmask.
    if (do_slotmask) {
        float Darkline_part_w = (3.0 - VMASK_USE_GM + VMASK_GAP) * VMASK_DARKLINE_SCALE;
        float Darkline_part_w_x2 = Darkline_part_w*2;
        bool odd_column = mod(vFragCoord_Tated.x + Darkline_part_w  , Darkline_part_w_x2) < Darkline_part_w;

        if (SCANLINE_SM_TYPE == 1.0) {
            // Slotmask is out oh phase every "odd" triple and mixed with
            // the straight scanline.
            // slotmask strength and stagger are configurable.
            // Acceptable values are with stagger around 79 (pi/4)
            if (odd_column) {
                float phase = pi + SCANLINE_SM_VOFFSET*0.022 * lum_scaled;
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
                lines = slotmask*slotmask;
            }
            return mix( 1.0, lines * (1-SCANLINE_DARK ) + SCANLINE_DARK, SCANLINE_SM_STRENGTH) ;
        }
    }



    //Morph scanline shape via input luminance
        float l = lum_scaled; // (already clamped)
        l = pow(l, SCANLINE_MINMAX_GAMMA);
        if (lum_scaled <= 0.5) {
            float l1 = pow(l, 4) * 15;
            lines = pow(lines, 1/sqrt(l1));
        } else {
            float l2 = (l-0.5)*2.0;
            lines = lines * (1-l2) + l2;
        }

        //Above code, unbranched, check if it works.
        /*    lum_scaled = pow(lum_scaled, SCANLINE_MINMAX_GAMMA);
            float l = lum_scaled; // (already clamped)
            float l1 = pow(l, 4.0) * 15.0;
            float l2 = (l - 0.5) * 2.0;
            float under_05 = pow(lines, 1.0 / sqrt(l1));
            float over_05 = lines * (1.0 - l2) + l2;
            float threshold_05 = step(0.5, l);
            lines = mix(under_05, over_05, threshold_05);
        */


    //Apply min brightness
        lines = lines * (1-SCANLINE_DARK ) + SCANLINE_DARK ;



    return lines;
}

float get_clamped_white_reference(vec3 pixel_in){
    float white_reference = max(max(pixel_in.r,pixel_in.g),pixel_in.b);
//     white_reference = min(white_reference,1.0); //Clamp here for both vmask and darklines.
    return white_reference;
}


float global_noise_static = 0.0;
float global_noise_ambi = 0.0;


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


vec3 pixel_alternate(vec3 source, float strength) {
    /*
             vec3 pixel_strobe = pixel_out.rgb * mod(params.FrameCount, 2);
                float max_c = max(pixel_out.r, max(pixel_out.g, pixel_out.b));
                float max_c_adpt = 1 - (max_c * 0.5);
                pixel_out.rgb = mix (pixel_out.rgb, pixel_strobe, ALT_BLANK_STRENGTH *    max_c_adpt       )   ;
    */
    
    // Emulate the low crt persistance by only drawing odd/even lines
    // on odd/even frames
    

    
    float line = vTexCoord.y * params.OutputSize.y;
    vec3 pixel_out = clamp(source, 0.0, 1.0);
    float l_period_half = ALT_BLANK_PERIOD / 2;
    
    
    //Use another alg that affects less dark colors for negative strength values.
    if (strength < 0.0) {
        strength *= -1;
        float max_c = max(pixel_out.r, max(pixel_out.g, pixel_out.b));
        float max_c_adpt = 1 - (max_c * 0.5);
        strength *= max_c_adpt;
    }

    
    
    
  
    
    if  (mod(float(params.FrameCount),2.0  ) == 1) {
        if  (mod(line,ALT_BLANK_PERIOD) > l_period_half) pixel_out=mix(source,vec3(0), strength) ;
    } else {
        if  (mod(line,ALT_BLANK_PERIOD) <= l_period_half) pixel_out=mix(source,vec3(0), strength) ;
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
    
    vec2 co = vTexCoord;

    co = zoomout_coords(co, -BEZEL_FRAME_ZOOM, 1.0);
    co.y = zoom1D(co.y, BEZEL_ASPECT_CORRECTION);
    
    if (DO_TILT == 1.0) 
        return tilt(co, vIsRotated, vec2(TILT_X, TILT_Y) * TILT_BEZEL_K);
            else
        return co;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////


vec4 fn_pixel_fgbg_image(sampler2D smp) {
    vec2 fg_image_offset=vec2(BG_IMAGE_OFFX,BG_IMAGE_OFFY);
    vec2 tex_size = textureSize(smp, 0); // * BG_ZOOM;
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
    vec4 pixel_bgover = textureLod_wrap(smp, back_coords, bg_over_lod, BG_IMAGE_WRAP_MODE);
    return pixel_bgover;
}



vec3 ambi_blend_image(vec4 image, vec3 ambi) {
    //mix or add ambient light with image, also allow force colorization in add mode.
    if (DO_AMBILIGHT == 0.0) return image.rgb;
    
    // Fake a transparent image when force colorization is requested
    // So that we can use the same code used for alpha blend.
    // Also multiply AMBI_BG_IMAGE_FORCE * AMBI_BG_IMAGE_BLEND_MODE to skip
    // force colorization when mode blend mode is not "ADD".
        float image_alpha_adapted = image.a - (AMBI_BG_IMAGE_FORCE * AMBI_BG_IMAGE_BLEND_MODE);

    image.rgb = (AMBI_BG_IMAGE_BLEND_MODE == 0.0) ? 
        mix(ambi.rgb, image.rgb, image_alpha_adapted) 
            : 
        image.rgb + (ambi.rgb * (1 - image_alpha_adapted)); 
        
    return image.rgb;
}

float gaussian_coefficient(float x, float sigma) {
    //restituisce un coefficiente gaussiano per x compreso tra 0 ed 1
    float coefficient = 1.0 / sqrt(2.0 * 3.14159265358979323846 * sigma);
    float exponent = -((x * x) / (2.0 * sigma));
    return coefficient * exp(exponent);
}

vec3 boxed_blur_x(sampler2D tex, vec2 co, float box_size, vec4 output_size) {
    /* blur tex in boxes of width box_size.
       eg: box_size=4:
       in: [abcd][edgh][ijkl]...
       out [AVG1][AVG2][AVG3]
       were AVG is a gaussian blur applied to each 4 elements separately.
    */
  
    //The current pixel, x:
        float x = co.x/output_size.z;
    //The group x belongs to, g:
        float g = ceil(x/box_size);
    //The first element of the group, x0
        float x0 = box_size * (g-1);            
    
    //Init output color:
        vec3 c = vec3(0.0);
    
    //We want a dumb arithmetic average?
        #define BOXB_DUMB 0.0
    //blurriness of output 
        #define BOXB_SIGMA 0.5
        
    //Iterate for every pixel in group:
        for (float xn = x0; xn < x0 + box_size; xn++) {
            //Normalize interval to 0..1 to get gauss coefficients afterwards
                float xn_normalizzato = normalize_range(xn, x0, x0 + (box_size-1));
            
            //Get gauss coefficient
                float coefficient = 1.0;
                if (BOXB_DUMB == 0.0)    
                    coefficient = gaussian_coefficient(xn_normalizzato, BOXB_SIGMA);
                        else 
                    coefficient = 1.0;

            //Translate integer element to offset in 0..1 range:
                float off = params.OutputSize.z*xn;
            c = c + texture(tex, vec2(off,co.y) ).rgb * coefficient ;
        }
    //reduce gain (why on earth is needed for gauss?): 
        if (BOXB_DUMB == 1.0) 
            c = c/box_size;
                else
            c = c/(box_size * 0.4);
    return c;
}


vec3 fn_pixel_content(vec2 coords) {
    vec3 pixel_in;
    vec3 pixel_glowed;
    vec3 pixel_bleed; //pixel_bleed is the color that will bleed over scanline gap.
                      //Used for SCANLINES_BLEEDING parameter only
    
    if  (DO_IN_GLOW == 1.0) {
        pixel_glowed = texture(in_glow_pass,coords).rgb;
        pixel_in = pixel_glowed;
    } else {
        pixel_in = texture(shift_and_bleed_pass,coords).rgb ;
    }
    
    
    //pixel_in = boxed_blur_x(shift_and_bleed_pass, coords,  params.OutputSize.x / params.OriginalSize.y, params.OutputSize);
                                                                            
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

    
    float scanline_or_dot_mat = 1.0; //init dot grid or scanline mask to 1.0
    
    //Dot mask
        if (DO_DOT_MATRIX == 1.0) {
            vec4 pixel_grid_mask = fn_pixel_dotmat(coords, pixel_out);
            //grid mask only is needed by halo to selectively light the grid.
                scanline_or_dot_mat = pixel_grid_mask.a;
            //rgb channel goes to pixel_out
            pixel_out = pixel_grid_mask.rgb;
        }
        
    //Scanlines (non-flickering)
        if  ( DO_SCANLINES == 1.0 ) {
            //Obtain a scanlined screen by multiplying the scanline mask and the pixel color.

                float lum = max(max(pixel_out.r, pixel_out.g), pixel_out.b);

                //The maximum possible brightness of the input color modified by glow,contrast and brightness.
                float scanline_mask = fn_scanline_mask(coords, SCANLINE_SM_TYPE > 0.0, lum, 0.0, vMax_inLum, vDo_Tate );
                pixel_out = min(pixel_out, 1.0) * ( scanline_mask + ( pixel_bleed * SCANLINES_BLEEDING * ( 1 - scanline_mask ) ));
                //Since scanlines and dot matrix are alternative and halo can white both, just use a single var for both:
                scanline_or_dot_mat = scanline_mask;
        }

        
    //Halo
        vec3 pixel_haloed = vec3(0.0);;

        if (DO_HALO == 1.0 ) {
            pixel_haloed = texture(halo_pass,coords).rgb;
            //Halo only on scanlines:
            pixel_out += pixel_haloed * scanline_or_dot_mat ;
            //Halo over scanlines gap too:
            pixel_out += pixel_haloed * (HALO_VS_SCAN) * (1 - scanline_or_dot_mat) ;

        }
    
    // Apply gamma out:
        if (DO_CCORRECTION == 1.0) 
            pixel_out = pow(max(pixel_out, vec3(0.0)),vec3(GAMMA_OUT));

    //Bloom
        if (DO_BLOOM == 1.0 ) {
            vec3 bloomed=texture(bloom_pass_final, coords).rgb ;
            pixel_out = bloomed + float(BLOOM_BYPASS < 0.5) * pixel_out;
        }
        
    //Vignette
        if (DO_VIGNETTE == 1.0) {
            float dist = length(vec2((coords.x-0.5)*vIn_aspect, coords.y-0.5));
            float vignette = smoothstep(V_SIZE,0.0,dist)*V_POWER;
            pixel_out = pixel_out * vignette + global_noise_static;
        }
        
    //Spot
        if (DO_SPOT == 1.0) {
                float dist = length(vec2((coords.x-0.5)*vIn_aspect, coords.y-0.5)+spot_offset);
                float spot = smoothstep(S_SIZE,0.0,dist)*S_POWER;
                pixel_out = pixel_out + spot + (global_noise_static * (1 - DO_VIGNETTE));
        }
    
    //Black frame insertion, made static, enable it in config.inc.
        #ifdef ALLOW_ALT_BLANK
            if (DO_ALT_BLANK == 1.0 ) {
                pixel_out.rgb = pixel_alternate(pixel_out.rgb, ALT_BLANK_STRENGTH );
                //pixel_out.rgb +=  vec3(random_fast(ALT_BLANK_STRENGTH, vTexCoord * mod(params.FrameCount, 2)   ));
            }
        #endif
        
    return pixel_out;
}


vec4 fn_pixel_bezel(vec2 coords_for_bezel, vec2 coords_for_mirror, float nightify_str) {
    
    //Can we skip Blank outside border and inner blank tube?
        vec4 inner_blank_rect = vec4(1-BEZEL_TUBE_BLANK_SIZE, 1-BEZEL_TUBE_BLANK_SIZE, BEZEL_TUBE_BLANK_SIZE, BEZEL_TUBE_BLANK_SIZE);
        if (is_first_outside_rect(coords_for_bezel, RECT01)  ||
            is_first_inside_rect(coords_for_bezel, inner_blank_rect)
        ) return vec4(0.0);

    vec4 bezel_in;    
    
    //Sample main bezel texture:
        #ifndef BEZEL_RES
            vec2 bezel_lut_size = textureSize(monitor_body_curved, 0); //no need to branch here if we assume straight and curved textures are the same size. //FIXME?
        #else
            vec2 bezel_lut_size = BEZEL_RES;
        #endif
        float bezel_frame_lod = log2(bezel_lut_size.y * (BEZEL_FRAME_ZOOM+1.0) /global.FinalViewportSize.y);
        
        if (BEZEL_USE_STRAIGHT < 0.5)
            bezel_in = textureLod(monitor_body_curved,coords_for_bezel,bezel_frame_lod);
                else
            bezel_in = textureLod(monitor_body_straight,coords_for_bezel,bezel_frame_lod);
    

    //Exit if the bezel is completely transparent (the tube)
        if (bezel_in.a == 0.0) return vec4(0.0);
        
    //Colorize the bezel (bezel.r expresses the luminance)
        vec3 bezel_out = bezel_color(bezel_in.r);
        bezel_out.rgb = fn_pixel_nightify(bezel_out.rgb, nightify_str );
    
    float lut_specular = bezel_in.g * BEZEL_SPCL_STRENGTH;
    float reflection_modifier = 0.0;

    //Reflections, can be skipped if blue channel is 0:
        if (bezel_in.b > 0.0) {
        //Reflections: Calculate the bezel roughness to apply to the reflecting area. (bezel_in.g expresses the specularity)
            float roughness = random_fast( 1/1080.0 * BEZEL_ROUGHNESS, vTexCoord );
            roughness *=  (1 - min(lut_specular * 10, 1.0)); // <-roughness over specular area looks bad.
            
        //Reflections:
            reflection_modifier = bezel_in.b; //bezel_in.b expresses how much the area is reflective
            
            //Sample the reflection pass with small offset to simulate the roughness
                vec4 pixel_mirrored = texture(reflected_blurred_pass, coords_for_mirror + roughness);
                float fcorners_shade = 1 - corners_shade(coords_for_bezel, 1.0) * BEZEL_CORNER_DARK;
                
            //Show less reflections in the corners
                pixel_mirrored.rgb *= fcorners_shade;

            //Push it over the specular areas and apply the reflection modifier
                pixel_mirrored.rgb = pixel_mirrored.rgb * (1 + lut_specular);

            //Apply reflections
                bezel_out += (pixel_mirrored.rgb * reflection_modifier);
        }

    //Mix ambient light over bezel? (branching this is worse)
        vec3 ambitemporalpass = texture(ambi_temporal_pass, vOutputCoord ).rgb;
        ambitemporalpass = max(ambitemporalpass, 0.0); //<-- antiglitch. Needed to avoid undefined variable on vulkan.
        vec3 pixel_ambilight = DO_AMBILIGHT * ( ambitemporalpass + global_noise_ambi);
            
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
        if (DO_VIGNETTE + DO_SPOT + DO_AMBILIGHT >0.0) {
            //Generate random noise.
                //global_noise = random(NOISEPOWER, vTexCoord * vDynamicSeed);
                //global_noise_ambi = global_noise * NOISEPOWER_AMBI_MUL;
            
                //The following are faster versions, the dynamic one needs a seed that changes over time
                //Calculated in Vertex shader for speed.
                    global_noise_ambi = random_fast(NOISEPOWER * NOISEPOWER_AMBI_MUL, vTexCoord * vDynamicSeed  );
                    global_noise_static = random_fast(NOISEPOWER, vTexCoord);
        }
    
    
    //Initial content coords
        vec2 co_content = vTexCoord;
        
    //Tilt?
        if (DO_TILT == 1.0)
            co_content = tilt(co_content, vIsRotated, vec2(TILT_X, TILT_Y));


    //Precalc Bezel coords, since it modifies content coords.
        vec2 co_bezel = vec2(0.0);
        if (DO_BEZEL == 1.0) {
            co_content = zoomout_coords(co_content, -vBEZEL_INNER_ZOOM_adapted , 1.0);
            co_bezel = get_scaled_coords_for_bezel();
        }

        
    //Curvature 
        //Curvature has to come after inner zoom or bezel curved border will not match content
        //curved border when inner zoom changes.
        if (DO_CURVATURE == 1.0  &&  ((GEOM_WARP_X != 0.0) || (GEOM_WARP_Y != 0.0))) {
            co_content = Warp_fast(co_content, vWarp_vexp, vWarp_arg2, GEOM_CUT_EARS);
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
            pixel_out = fn_pixel_content(co_content) * canvas_busy;
              

    //Draw Bezel
        vec4 pixel_bezel;
        //SKIP LOGIC is inside fn_pixel_bezel
        if (DO_BEZEL == 1.0) {
            vec2 co_mirror = zoom(co_content, 1/BEZEL_REFL_ZOOMOUT_ROOM);
            pixel_bezel = fn_pixel_bezel(co_bezel, co_mirror, BG_IMAGE_NIGHTIFY);
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
                    pixel_ambi = texture(ambi_temporal_pass, co_ambi).rgb;
                    pixel_ambi += global_noise_ambi * (20 * (3.0-(pixel_ambi.r+pixel_ambi.g+pixel_ambi.b))) ;
                    pixel_under_content = pixel_ambi;
                }
            
            //Background image:
                if (DO_BG_IMAGE == 1.0 && BG_IMAGE_OVER == 0.0) {
                    vec4 pixel_bg_image = fn_pixel_fgbg_image(bg_under);
                    pixel_bg_image.rgb = fn_pixel_nightify(pixel_bg_image.rgb, BG_IMAGE_NIGHTIFY );
                    pixel_bg_image.rgb = ambi_blend_image(pixel_bg_image, pixel_ambi);        
                    pixel_under_content = pixel_bg_image.rgb;
                }
            
        }

        
        //Smooth the image corners: canvas_busy (the alpha mask) is a white rect with shaded borders.
            pixel_out = mix (pixel_under_content, pixel_out, canvas_busy);
 
          
        //Backdrop
            if (DO_BACKDROP == 1.0)
                pixel_out += pixel_backdrop_image();

            
        //Foreground image
            if (DO_BG_IMAGE + BG_IMAGE_OVER == 2.0) {
                vec4 pixel_fg_image = fn_pixel_fgbg_image(bg_over);
                pixel_fg_image.rgb = fn_pixel_nightify(pixel_fg_image.rgb, BG_IMAGE_NIGHTIFY );
                
                pixel_out = mix(pixel_out, pixel_fg_image.rgb, pixel_fg_image.a);
                
                if (DO_AMBILIGHT + AMBI_BG_IMAGE_BLEND_MODE == 2.0) { 
                    vec3 pixel_ambi_local = texture(ambi_temporal_pass, vOutputCoord ).rgb;
                    pixel_ambi_local = DO_AMBILIGHT * (pixel_ambi_local + global_noise_ambi);
                    pixel_ambi_local = max(pixel_ambi_local, 0.0); //<-- antiglitch. Needed to avoid undefined variable on vulkan.
                    float ambi_mask = create_ambi_colorize_shade(co_bezel);
                    float fg_image_alpha_adapted = max(pixel_fg_image.a - AMBI_BG_IMAGE_FORCE, 0.0);
                    pixel_out = pixel_out + (pixel_ambi_local.rgb * (ambi_mask) * (1- fg_image_alpha_adapted));
                }
            }
  
     

    //For debug purposes:
        //quad split screen
        //if ( (vOutputCoord.x < 0.5  && vOutputCoord.y > 0.5) || (vOutputCoord.x > 0.5  && vOutputCoord.y < 0.5)  ) pixel_out = texture(flick_and_noise_pass,vOutputCoord).rgb;
        //split screen
        //if (vTexCoord.y < 0.5) pixel_out = texture(flick_and_noise_pass,vTexCoord).rgb;
        //pixel_out = texture(reflected_blurred_pass, vTexCoord).rgb;
        
        
    FragColor = vec4(pixel_out, 1.0);
   
    //FragColor = vec4(texture( reflected_blurred_pass, co_mirror).a);
    
}

