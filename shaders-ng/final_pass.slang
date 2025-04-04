#version 450

/* This pass:
 * Composes the previous passes
 * Does masks, spot, bezel, vignette, background image (anything else?)
 */

                                //#define DEBUG_TEXTURE Original
                                //#define DEBUG_TEXTURE colortools_and_ntsc_pass
                                #define DEBUG_TEXTURE halo_pre_gamma_pass
//#define DEBUG_PRINT_VALUE
//#define PRINTED_VALUE texture(DEBUG_TEXTURE, vec2(0.5)).a
//#define PRINTED_VALUE global.OriginalFPS
    
//#define DEBUG_QUAD_SPLIT
//#define DEBUG_DUAL_SPLIT_X
//#define DEBUG_DUAL_SPLIT_Y
//#define DEBUG_DUAL_SPLIT_Y_GAMMA
//#define DEBUG_DUAL_SPLIT_MIRROR_X
//#define DEBUG_DUAL_SPLIT_MIRROR_X_GAMMA
//#define DEBUG_SHOW_CLIP


#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;
layout(location = 2) out vec2 vBg_img_coords;
layout(location = 3) out float vIsRotated;
layout(location = 4) out float vScanlinePeriod;
layout(location = 5) out float vInterlace_offset;
layout(location = 6) out float vIn_aspect;
layout(location = 7) out float vDo_Tate;
layout(location = 9) out vec4 vPG_offsets_and_size;
layout(location = 10) out float vInteger_fragment_x;
layout(location = 11) out vec2 vPG_freq_base_screen_unfloored;
layout(location = 12) out float vPG_period_multiplier_x;
layout(location = 13) out vec2 vPG_OriginalSize_tated_mul_pi;
layout(location = 15) out float vPG_mask_height;
layout(location = 17) out float vDo_pixelgrid_h;
layout(location = 18) out float vFake_scanline_period;
layout(location = 19) out float vPG_y_shift;

#ifdef DEBUG_PRINT_VALUE
    layout(location = 31) out float vfprintvalue; 
#endif

// I_am_a_placeholder_keep_reading;
//..to remind you that location = 31 is the last accepted by vulkan
//or Retroarch crashes or nvidia starts to give Xids.
//unsure if the issue is with retroarch or with vulkan specs.
//If in short, consider to pack more datas into vec2,3,4.
//But bear in mind that exceding the limit leads to
//slowdowns.

#include "includes/functions.include.slang"

#define PI_15 4.71238898038469 //pi*1.5


vec2 get_zooms_modifier(float do_tate, bool bNeed_NO_integer_scale, bool isrotated) {
    // This function is meant to live in vertex shader; its purpose is to
    // give the final scale factor by taking in consideration various zoom modifiers.
    //It works by calculating the new 0.0 and 1.0 coords then measuring the new distance between them

    // WARNING: This has to be in sync with the code, so everytime a scaling flow is modified, this needs to be updated. WARNING
    // WARNING: This has to be in sync with the code, so everytime a scaling flow is modified, this needs to be updated. WARNING
    // WARNING: This has to be in sync with the code, so everytime a scaling flow is modified, this needs to be updated. WARNING

    vec2 co_scaled_min = vec2(0.0);
    vec2 co_scaled_max = vec2(1.0);

    if ( bNeed_NO_integer_scale ) {
        co_scaled_min = get_scaled_coords_aspect(co_scaled_min, global.FinalViewportSize, vIn_aspect, isrotated);
        co_scaled_max = get_scaled_coords_aspect(co_scaled_max, global.FinalViewportSize, vIn_aspect, isrotated);
    } else {
        co_scaled_min = integer_scale(co_scaled_min, vIn_aspect, isrotated, do_tate, GAME_GEOM_INT_SCALE-1.0 );
        co_scaled_max = integer_scale(co_scaled_max, vIn_aspect, isrotated, do_tate, GAME_GEOM_INT_SCALE-1.0 );
    }


    //vfprintvalue = 1/(co_scaled_max.y - co_scaled_min.y);
    return 1 / vec2(co_scaled_max.x - co_scaled_min.x,
                co_scaled_max.y - co_scaled_min.y );

}


void main() {
    gl_Position = global.MVP * Position;
    bool bIsRotated = is_rotated();
    vIsRotated = float(bIsRotated);

    vDo_Tate = need_tate(bIsRotated);

    vIn_aspect = get_in_aspect();

    //Calculate vTexcoord as fractional or integer scaled?
        bool bNeed_NO_integer_scale = need_NO_integer_scale();
        if ( bNeed_NO_integer_scale )
            vTexCoord = get_scaled_coords_aspect(TexCoord,global.FinalViewportSize, vIn_aspect, bIsRotated);
        else
            vTexCoord = integer_scale(TexCoord, vIn_aspect, bIsRotated, vDo_Tate, GAME_GEOM_INT_SCALE-1.0 ) + vec2( GAME_GEOM_OFF_FIX /10000);

    vTexCoord += 0.00001;
    

    vOutputCoord = TexCoord ;

    //Help scanline/pixelgrid code too:
        bool bIs_Interlaced = is_interlaced();

        //Scanline period:
            vScanlinePeriod = 1.0; //Base 1x period
            vInterlace_offset = 0.0; //No interlace

            if (scanlines_will_alternate(bIs_Interlaced))  {
                //Halve the scanline period, since they will interlace:
                vScanlinePeriod = 0.5;
                vInterlace_offset = PI_15*0.5;
                //Alternate scanlines on even/odd frames
                if (frame_is_even())
                    vInterlace_offset += PI_15;
            }


    //Pixelgrid: get mask type; .rgb contains layout, .a contains the size.
    //we use 2 different layouts for floored and unfloored coords, because
    //with unfloored coords we move the gap half beginning, half end,
    //while with floored coords it must have its own integer spot.
        if (PIXELGRID_SIZE_W == 0.0 || PIXELGRID_MUL_X != 1.0)
            vPG_offsets_and_size = PG_get_hmask_preset_unfloored() ;
                else
            vPG_offsets_and_size = PG_get_hmask_preset_floored() ;
    
       //scale offsets to be used by sin:
        vPG_offsets_and_size.rgb *= (pi / vPG_offsets_and_size.a);
        
    //Pixelgrid: Calc base freqs
            vec2 PG_OutputCoord_tated;
            vec2 PG_OutputSize_tated;
        //Tate ?
            if (vDo_Tate == 0.0) { 
                PG_OutputSize_tated   = params.OutputSize.xy;
                PG_OutputCoord_tated  = vOutputCoord.xy + vec2(0.00001);
                vPG_OriginalSize_tated_mul_pi = params.OriginalSize.xy * pi;
            } else {
                PG_OutputSize_tated   = params.OutputSize.yx;
                PG_OutputCoord_tated  = vOutputCoord.yx;
                vPG_OriginalSize_tated_mul_pi = params.OriginalSize.yx * pi;
            }

        vInteger_fragment_x = PG_OutputCoord_tated.x * PG_OutputSize_tated.x; //will be floored in fragment shader.

        //the following unfloored coords are needed by sin/cos later to understand if we are on an even or odd mask
            float rgbw_size;
            if (PIXELGRID_OFFSET_CORE * PIXELGRID_OFFSET_CORE_W > 0.0)
                rgbw_size = 1/PIXELGRID_OFFSET_CORE_W;
            else
                rgbw_size = 1/vPG_offsets_and_size.a;
    
            vPG_freq_base_screen_unfloored = pi * vec2(rgbw_size, 0.5) * (PG_OutputCoord_tated * PG_OutputSize_tated);

    //pixelgrid: doublescan?
                if (need_doublescan() )
                    vPG_OriginalSize_tated_mul_pi *= 2.0;

    //Pixelgrid: adapt period multiplier
        vPG_period_multiplier_x = 1/PIXELGRID_MUL_X;
        if (vPG_period_multiplier_x < 0.0) vPG_period_multiplier_x = 1/-vPG_period_multiplier_x;



    //Pixelgrid Y mask: adapt mask height
        vPG_mask_height = PIXELGRID_Y_MASK_HEIGHT;
        if (vPG_mask_height < 0.0) vPG_mask_height = 1/-vPG_mask_height;

    //Pixelgrid Y mask: Select an y shift that gives the sharpest lines
        bool y_mask_align_to_screen_lines = (PIXELGRID_Y_MASK_SHIFT < 0.0)      && //Engage when param is < 0.0 (auto) and
                                            (PIXELGRID_Y_MASK_COORDS == 1.0)    && //only when when using screen coords and
                                            (fract(1.0/vPG_mask_height) == 0.0);   //only when the multiplier is integer
    
        if (y_mask_align_to_screen_lines ) {
            vPG_y_shift = vPG_mask_height * (pi / 4.0);
        } else {
            vPG_y_shift = PIXELGRID_Y_MASK_SHIFT * pi ;
        }
        
        
    //Pixelgrid: do horizontal if enabled, but skip it if user doesn't want it on interlaced content.
        vDo_pixelgrid_h = float( pixelgrid_h_needed() );


    // Fake or Faker integer scanlines:
    // We are going to compute an amount of lines that is integer multiple of the screen lines and that
    // is near to the real input/core lines
    vFake_scanline_period = 0.0;
    
    
    // For automatic Fake scanline managment, we compute a treshold under which
    // fake integer scanlines will be used.
    // (Logic is skipped if integer scaling is requested.)
        bool very_lowres_y = false;
        #define MIN_SCREEN_CORE_RATIO 3.5 //We want at least that screen lines per single scanline.
        if ( bNeed_NO_integer_scale ) {
            vec4 out_size = params.OutputSize;
            vec4 ori_size = params.OriginalSize;
            vec2 zoom_modifier = get_zooms_modifier(vDo_Tate, bNeed_NO_integer_scale,bIsRotated);
            if (vDo_Tate == 1.0) {
                out_size.xy = out_size.yx;
                ori_size.xyzw = ori_size.yxwz;
                zoom_modifier.xy = zoom_modifier.yx;
            }
            if (need_doublescan()) ori_size.yw*=vec2(2.0, 1/2.0); //double period?
            ori_size.y*=vScanlinePeriod; //helve period?
            float OutputHeightZoomed = out_size.y*zoom_modifier.y;
            float screen_core_ratio = OutputHeightZoomed / ori_size.y;
            if (screen_core_ratio < MIN_SCREEN_CORE_RATIO)
                very_lowres_y = true;
        }
    
    //Conditions for fake scanlines are: 
    // - user wants fake/faker integer scanlines when content is interlaced (*1)
    //   or
    // - user always wants fake integer scanlines. (*2)
    //   or
    // - user wants automatic fake integer scanlines managment and screen is too low res (*3)
    //   or
    // - user wants fake integer scanlines when content is double-scanned (*4) // <-- edit, ditched as it seems useless to me.
    

    
    bool fake_scanlines_needed =  (PIXELGRID_INTR_DISABLE_Y <= -1.0 && bIs_Interlaced) || //(*1)
                                  (PIXELGRID_COREY_FAKE_SCAN == 1.0) ||                   //(*2)
                                  (PIXELGRID_COREY_FAKE_SCAN == -1.0 && very_lowres_y);    //(*3)
                                  //(PIXELGRID_COREY_FAKE_SCAN == 2.0 &&  need_doublescan() ); //(*4)
                
                                  
    if ( fake_scanlines_needed ) {
        vec4 out_size = params.OutputSize;
        vec4 ori_size = params.OriginalSize;
        vec2 out_coord = vOutputCoord;
        vec2 zoom_modifier = get_zooms_modifier(vDo_Tate, bNeed_NO_integer_scale,bIsRotated);
        if (vDo_Tate == 1.0) {
            out_size.xy = out_size.yx;
            ori_size.xyzw = ori_size.yxwz;
            out_coord.xy = out_coord.yx;
            zoom_modifier.xy = zoom_modifier.yx;
        }

        // Modify the y line size ?
            float target_line_size = ori_size.w ;
            if ( need_doublescan() ) {
                target_line_size /= 2.0; //halve line size for doublescan
            } else if (PIXELGRID_INTR_DISABLE_Y == -2.0 && bIs_Interlaced) {
                target_line_size /= 1.5; //reduce line size for fakeR scanlines on interlaced screens.
            }
            
        // compute a rounded number of lines that integer fits the screen
            float rounded_denominator = round( (out_size.y*zoom_modifier.y) * target_line_size);
                  rounded_denominator = max(rounded_denominator, 2.0); // avoid division by 0  and ensure (, 2.0)
                                                                       // scanline gaps are drawn even on tiny output sizes.
            
            float fake_scanlines_numlines = out_size.y / rounded_denominator;
            
        //Compute the final fake scanline period
            vFake_scanline_period = pi * fake_scanlines_numlines * out_coord.y;
                
        //This somehow aligns better the scanline to the screen line:
            vInterlace_offset+=1.0;
    }
    
    //Fragment shader will use that just one time that way. => precalc.
    vPG_offsets_and_size.a = pi/vPG_offsets_and_size.a;

}



#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 2) in vec2 vBg_img_coords;
layout(location = 3) in float vIsRotated;
layout(location = 4) in float vScanlinePeriod;
layout(location = 5) in float vInterlace_offset;
layout(location = 6) in float vIn_aspect;                              
layout(location = 7) in float vDo_Tate;
layout(location = 8) in vec3 vDotMat_Grid_Color;
layout(location = 9) in vec4 vPG_offsets_and_size;
layout(location = 10) in float vInteger_fragment_x;
layout(location = 11) in vec2 vPG_freq_base_screen_unfloored;
layout(location = 12) in float vPG_period_multiplier_x;
layout(location = 13) in vec2 vPG_OriginalSize_tated_mul_pi;
layout(location = 14) in float vDotMat_Grid_Sharpness;
layout(location = 15) in float vPG_mask_height;
layout(location = 16) in float vDeltaRenderOk;
layout(location = 17) in float vDo_pixelgrid_h;
layout(location = 18) in float vFake_scanline_period;
layout(location = 19) in float vPG_y_shift;

#ifdef DEBUG_PRINT_VALUE
    layout(location = 31) in float vfprintvalue;
#endif

layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 2)  uniform sampler2D bloom_pass_final;
layout(set = 0, binding = 10) uniform sampler2D in_glow_pass_x;
layout(set = 0, binding = 11) uniform sampler2D in_glow_pass;
layout(set = 0, binding = 12) uniform sampler2D halo_pass;


layout(set = 0, binding = 15) uniform sampler2D DEBUG_TEXTURE;




#define HALF_PI 1.5707963267949
#define QUARTER_PI 0.785398163397448

#include "includes/functions.include.slang"


vec2 vOutputCoord_adapted;
vec2 get_vOutputCoord_adapted() {
    return vOutputCoord_adapted;
}


vec3 morph_shape_full_vec3(vec3 shape, vec3 l, float steep, float gamma ) {
    vec3 l_pow = pow(l,vec3(gamma));
    vec3 l2 = min(l_pow * 16, steep); //min faster than clamp
    vec3 s1 = pow(shape, inversesqrt(l2));
    //vec3 s2 = (1-s1) * l_pow;
        //==  lpow - lpow * s1;
        //== -lpow * s1 + lpow;
    vec3 s2 = fma(-l_pow, s1,  l_pow); //ASM PROOF, faster.
    return (s2/(steep)) + s1;
}


vec3 morph_shape_full_no_steepness_vec3(vec3 shape, vec3 l, float gamma) {
    vec3 l_pow = pow(l,vec3(gamma));
    vec3 l2 = clamp(l_pow * 16, 0,1); //clamp faster than min.
    vec3 s1 = pow(shape, inversesqrt(l2));
    vec3 s2 = (1-s1) * l_pow;
        // == 1*l_pow  - s1*l_pow
        // == -l_pow*s1 + l_pow
    //vec3 s2 = fma(s1, -l_pow, l_pow); //ASM PROOF, slower.
    return s2 + s1;
}


vec3 morph_shape(vec3 shape, vec3 power, float steep, float gamma ) {
   return morph_shape_full_vec3(shape, power, steep, gamma);
}


vec4 fn_pixel_grid(vec2 in_coords, vec4 pixel_in, float min_inLum, float max_inLum) {
    //^ 15fps ^

    //Tate ? (other outputsize,originalsize and outputcoords "tated" in vertex shader.)
        in_coords.xy = mix_step(in_coords.xy, in_coords.yx, vDo_Tate);
       //in_coords = in_coords - global.flick_and_noise_passSize.zw*0.5; //<-- needed if for whatever reason you want to draw scanlines and vgaps in first_pass

        vec2 freq_base_core = in_coords * vPG_OriginalSize_tated_mul_pi ;

        //Use fake scanlines?
        if (vFake_scanline_period > 0.0)
            freq_base_core.y = vFake_scanline_period;

    //Screen coords:
    //Floor x screen coords when using non 1.0x sizes.
    //y screen coords appear to work just fine even if we don't floor them,
        vec2 freq_base_screen;
        #define PG_freq_base_screen_x vPG_offsets_and_size.a
        if (PIXELGRID_MUL_X == 1.0) {
            freq_base_screen = vec2( (PG_freq_base_screen_x) * floor(vInteger_fragment_x), vPG_freq_base_screen_unfloored.y);
        } else {
            freq_base_screen = vPG_freq_base_screen_unfloored;
        }

    //Switch frequency between core and screen and apply asked multipliers
        vec2 freq_base = freq_base_core * vec2(vPG_period_multiplier_x, 1.0) ;
        vec2 freq_base_unfloored = freq_base_core;
        //vec2 freq_base_unfloored = freq_base_core * vec2(vPG_period_multiplier_x, 1.0) ; <--- core can be multiplied too, why not?
        if (PIXELGRID_SIZE_W == 1.0) {
            freq_base.x = freq_base_screen.x * vPG_period_multiplier_x;
            freq_base_unfloored.x = vPG_freq_base_screen_unfloored.x * vPG_period_multiplier_x;
        }
    
    // Shadowmask
    // Works by staggering odd rows by 1.5X triad
    // Pay attention to phosphor width; if too low may, vanify shadowmask.
    vec3 PG_offsets = vPG_offsets_and_size.rgb + //base offsets staggered (+)
                float( PIXELGRID_DO_SHADOWMASK *                                      // user wants shadowmask
                       sin(freq_base_screen.y * 2.0 / PIXELGRID_SHADOWMASK_H ) > 0.0  // sin > 0.0 means the row is even
                      ) * PIXELGRID_SHADOWMASK_SHIFT ;                                // stagger by 1.5

        
    vec3 freq_rgb = freq_base.xxx - PG_offsets;

    //The following is needed by scanlines and vertical mask
    //sin() tell use if the current cell position is odd or even:

        //FIXME: is_even should be a single phosphor property.
        //If i manage to find a way to do it, i could use
        //decon_stagger.r,g,b to stagger single phosphors.
        //And that way, i could blend staggered triads together
        //without "cuts" between them.
        //FIXME FIXME: Unsure if the previous statement is still valid.

        float sin_check_offset = sin(freq_base_unfloored.x);
        float is_even = step(sin_check_offset, 0.0);

    //Scanlines and fake slotmask =========================================================================
        vec3 rgb_h = vec3(1.0);
        vec3 dedot_mix = vec3(0.0);
        
        vec3 phosphor_height = vec3(1.0);
        if (vDo_pixelgrid_h > 0.5) {
            //Scanlines: compute each phosphor height according to input luminance
                phosphor_height = map_range(pixel_in.rgb, min_inLum, max_inLum, PIXELGRID_MIN_H, PIXELGRID_MAX_H);
                
            //We can offset trias to emulate fake core level slotmask by applying the optional offset to emulate the slotmask on even cells
                float fakeslot_stagger_offset =  is_even * PIXELGRID_OFFSET_CORE * pi;
            //get 3 staggers for y deconvergence.
                vec3 decon_stagger = vec3( PIXELGRID_DECON_R_H, PIXELGRID_DECON_G_H, PIXELGRID_DECON_B_H);
                
            #ifdef HQ_DECON
                //Sync decon stagger to deconvergence set in shift_and_bleed pass.
                float dist_from_edge = distance_from_edge_linear(in_coords, EDGE_DEFOCUS_AREA_INV);
                float offset_multiplier = mix(EDGE_DEFOCUS, 0.0, dist_from_edge) * (DO_SHIFT_RGB * OFFSET_STRENGTH);
                decon_stagger = vec3(DECON_RY,DECON_GY,DECON_BY)*pi/2.0 * (offset_multiplier * NEW_SCALEMOD_Y) ;
            #endif
          
            //Compute final sin mask with staggering
            vec3 rgb_h_sin = sin( (freq_base_core.y * vScanlinePeriod) + fakeslot_stagger_offset - decon_stagger + vInterlace_offset );

            //make it positve with doubled frequency:
                rgb_h_sin = (rgb_h_sin * rgb_h_sin);

            //Compute dedot mix here for use in h mask and vmask2 later
                //dedot_mix = vec3(  PIXELGRID_H_DEDOT - PIXELGRID_H_DEDOT * rgb_h_sin.x);
                dedot_mix = vec3( fma( -PIXELGRID_H_DEDOT, rgb_h_sin.x, PIXELGRID_H_DEDOT)); //ASM PROOF: SAME
                dedot_mix = dedot_mix *(pixel_in.rgb/max_inLum);
                                
            //Finally get 3 sines out of the previous one by applying height modifiers
                rgb_h = morph_shape(rgb_h_sin, phosphor_height, PIXELGRID_NO_INTERBLEED_H, PIXELGRID_GAMMA_H);

                rgb_h = mix(vec3(1.0), rgb_h, DO_PIXELGRID_H);
                
                rgb_h = clamp(rgb_h, 0.0,1.0); //max(x,0.0) should suffice, but somehos produces slower code.
                
                #ifdef HQ_DECON
                    // Y Defocusing causes scanlines gaps to blend, so mix the scanlines mask with the original color
                    // since the original color will be multiplied again for rgb_h later on, pow it to 0.9 to avoid excessive gamma increase.
                    
                        float mixing_factor =         // the mixing factor will depend on:
                              (DO_SHIFT_RGB           // the fact that we are doing defocusing
                            * EDGE_DEFOCUS_DO_BLUR) 
                            * ((1-dist_from_edge)     // the distance from the center
                            * DO_PIXELGRID_H) ;       //the scanline strength
                    rgb_h = mix( rgb_h,  mix(vec3(1.0), pixel_in.rgb, 0.9), mixing_factor);
                #endif
        }



    //Horizontal Triad Mask: ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
        vec3 rgb_w = vec3(1.0);
        vec3 rgb_grille_basal = vec3(0.0);

        if (DO_PIXELGRID_W > 0.0) { //4%
            // get 3 sines in black/white,   | sin(freq_rgb)
            // make them always positive and double frequency  | sin(freq_rgb) * sin(freq_rgb)
            // and scale Max width according to pre-gains:
                vec3 phosphor_width = map_range(pixel_in.rgb, min_inLum, max_inLum, PIXELGRID_MIN_W, PIXELGRID_MAX_W);
        
            //Get final phosphor width:
                rgb_w = morph_shape_full_no_steepness_vec3( sin(freq_rgb) * sin(freq_rgb), phosphor_width, PIXELGRID_GAMMA_W); //2%
                
            //Dedot rgb mask between h mask.
            //This work only when there are dots and have the countereffect when there are not.
            //This happen because flattening the rgb mask will make unflattened rgb triads
            //more evident, so this has to be used only when needed.
                rgb_w = mix(rgb_w, phosphor_width, dedot_mix);

            //lower strength via user parameter?
                rgb_w = mix(vec3(1.0), rgb_w, DO_PIXELGRID_W);
                
            //"export" naked vertical grille
                rgb_grille_basal = (rgb_w * rgb_w) * (rgb_w * rgb_w) * (PIXELGRID_BASAL_GRID*0.0025);
                
        }


    //Vertical mask .:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.
    // can be used for slotmask,aperturegrille ... or scanlines, but they would have a boxed shape.
        vec3 darklines_mask=vec3(1.0);

        if (PIXELGRID_Y_MASK > 0.0) {
            //Compute phosphors height mask with the right reference coords.
            // Faster than if/then (ASM proof and tests):
            float ph_mask_height = vPG_mask_height * mix(freq_base_core.y, freq_base_screen.y, PIXELGRID_Y_MASK_COORDS);
            /*float ph_mask_height;
            if ( PIXELGRID_Y_MASK_COORDS == 1.0 )
                ph_mask_height = freq_base_screen.y * vPG_mask_height;
            else
                ph_mask_height = freq_base_core.y * vPG_mask_height;
            */

            
            //phosphors mask stagger
                #define PH_MASH_OFFSET  (PIXELGRID_Y_MASK_OFFSET * HALF_PI )

                
            //Use abs(cos) (later 1-abs(cos) to get horizontal gaps, use pow to make them steep.
            //Stagger them by PH_MASH_OFFSET on even triads
                float mask_shape = abs(cos(  vPG_y_shift  + ph_mask_height  + (PH_MASH_OFFSET * is_even)) ) ;
                mask_shape = pow(mask_shape, PIXELGRID_Y_MASK_STEEP);


                // We can make the stagger dark line less pronunced
                // on its sides so that lateral staggered color
                // can bleed over.
                // but you really need to have God eyes to notice any improvement, if any imho.
                // Also, this would probably alter the colors (?)
                // So keep it disabled.
                //    float Bleed_force = SERVICE1; //0.02 seems a realistic value.
                //    float side_visibility = pow(pow(sin_check_offset,2.0),Bleed_force);
                //    mask_shape = mask_shape* side_visibility;
                // return vec4(mask_shape);

            //Get per channel input luminance by clamping pixel_in and applying hmask
                vec3 lum = clamp(pixel_in.rgb * rgb_w, 0.0, 1.0); //2 cycles less when using max or min, didn't bother.
            //Adapt the luminance effect via input parameter
                vec3 lum_adapted = (1-lum*PIXELGRID_Y_MASK_ON_WHITE);
            //Calc final mask visibility as the minimum between tha configured visibility and luminosity effect
                vec3 V=min( lum_adapted, vec3(PIXELGRID_Y_MASK) );
                
                //SlotMask de-Hive take 1: draws slotmask only on edges on dark parts. 109.45
                //vec3 V_EVERYWHERE = V;
                //vec3 V_JUST_EDGES =  V * (1-rgb_h);
                //V = mix(V_EVERYWHERE, V_JUST_EDGES, pixel_in.rgb*max_inLum);

                //SlotMask de-Hive Take 2: simply modulates slotmask visibility on dark colors. 109.5
                //V=V* pow(pixel_in.rgb,vec3(SERVICE1));

                //SlotMask de-Hive Take 3, takes care of phosphor height and scanlines visibility. 109.2
                //vec3 V_dehived = V*pow(phosphor_height,vec3(PIXELGRID_Y_MASK_OFFSET_DEHIVE));
                //V = mix(V, V_dehived, vec3(DO_PIXELGRID_H));

                //SlotMask de-Hive Take 4, takes care of phosphor height,scanlines visibility and keep edge slotmask.
                //the slower, but way better, keep this.
                vec3 V_JUST_EDGES =  V * (1-rgb_h);
                vec3 V_dehived = mix(V_JUST_EDGES, V, pow(phosphor_height,vec3(PIXELGRID_Y_MASK_OFFSET_DEHIVE)));
                V = mix(V, V_dehived, vec3(DO_PIXELGRID_H));
                
            //apply user visibility modifier to the mask
                darklines_mask = 1-(mask_shape*V);
            //Try to get a more brillant/sparkling look by highering the darklines
            //effect (sub) and pushing the source color, useful for slotmasks.
                vec3 PG_spark = (PIXELGRID_Y_SPARK * V) * (0.5/vPG_mask_height);         
                darklines_mask = (darklines_mask-0.5) * (1+PG_spark) + 0.5 ; 
        }

        

    //Finally put H mask, Scanlines and darklines masks together:
        vec3 mask = rgb_w * rgb_h * darklines_mask;


    //Apply Overmask:
            mask = PIXELGRID_OVERMASK * (mask - 0.5) + 0.5;
            pixel_in.rgb = mix(pixel_in.rgb, pixel_in.rgb * PIXELGRID_OVERMASK, PIXELGRID_OVERMASK);
            
            //mask = mix(vec3(1.0), mask * PIXELGRID_OVERMASK * 1.2, PIXELGRID_OVERMASK);
            
            
    //Apply the mask to pixel_in and clamp the minimum to the unexcited grille.
        vec3 mask_and_grille = max(mask * pixel_in.rgb, rgb_grille_basal);

    //return it with alpha channel containing the mask itself, so that halo can selectively light it.
        return vec4( mask_and_grille , dot(rgb_h, vec3(0.3333)));
}



float get_clamped_white_reference(vec3 pixel_in){
    float white_reference = max(max(pixel_in.r,pixel_in.g),pixel_in.b);
//     white_reference = min(white_reference,1.0); //Clamp here for both vmask and darklines.
    return white_reference;
}


//////////////////////////////////////////////////////////////////////////////////////////////////////

vec3 antighost(vec3 c) {
    #ifndef D3D_WORKAROUND
        #ifdef LCD_ANTIGHOSTING
            #ifndef LCD_ANTIGHOSTING_CEIL
                #define LCD_ANTIGHOSTING_CEIL 1.0
            #endif
            if (LCD_ANTIGHOSTING > 0.0) {
                if (frame_is_even()) {
                    vec3 feedback = texture(final_passFeedback, vOutputCoord).rgb;
                    vec3 diff=(feedback - c)*LCD_ANTIGHOSTING;
                    diff = sign(diff) * min( abs(diff), vec3(LCD_ANTIGHOSTING_CEIL));
                    c = mix(c, c-diff, 0.5);
                }
            }
        #endif
    #endif
    return c;
}


vec3 fn_pixel_content(vec2 coords) { 
    vec2 warpedglow = vec2(0.0);
    
    #ifndef SKIP_WARPEDGLOW_Y
        warpedglow.y = texture(in_glow_pass, coords + delta_render_enabled() * eps).a;
        // ^^ Delta render performance suffer alot if not adding eps here on my haswell for unknown reasons.
        // ...probably some failed compiler optimization issue.
    #endif
    #ifndef SKIP_WARPEDGLOW_X
        warpedglow.x = texture(in_glow_pass_x, coords).a;
    #endif
    coords += warpedglow.xy;

    //#define USE_QUILEZ   
    #ifdef USE_QUILEZ
        vec4 pixel_out = texture(in_glow_pass, coords_QULEZ(coords, global.upscale_passSize));
    #else
        vec4 pixel_out = texture(in_glow_pass, coords);
    #endif
        
    float dot_mat_or_pixelgrid = 1.0; //init dot grid or scanline mask to 1.0
    
    //Pixel grid
        if (DO_PIXELGRID == 1.0) {
            //1264,20488,22262, 108.5
            float vMax_inLum = mix( 1.0, 
                                    apply_contrast_brightness(1.0, CONTRAST, BRIGHTNESS) * max(IN_GLOW_POWER, 1.0), 
                                    DO_CCORRECTION );           
            //1268,20501,22268 108.3
            /*float vMax_inLum = 1.0;
            if (DO_CCORRECTION == 1.0)
                 vMax_inLum = apply_contrast_brightness(1.0, CONTRAST, BRIGHTNESS) * max(IN_GLOW_POWER, 1.0);
            */
            vec4 pixel_grid = fn_pixel_grid(coords, pixel_out, 0.0, vMax_inLum);
            //grid mask only is needed by halo to selectively light the grid.
                dot_mat_or_pixelgrid = pixel_grid.a;
                pixel_out.rgb = pixel_grid.rgb;
        }

    //Halo
        if (DO_HALO == 1.0 ) {
            vec3 pixel_haloed = texture(halo_pass, coords).rgb;                
            pixel_out.rgb = pixel_out.rgb + pixel_haloed * mix( dot_mat_or_pixelgrid, 1.0, HALO_VS_SCAN);            
        }

    // Apply gamma out:
        pixel_out.rgb = pow(max(pixel_out.rgb, vec3(0.0)),vec3(GAMMA_OUT));

    //Bloom
        if (DO_BLOOM == 1.0 ) {
            vec3 bloomed=texture(bloom_pass_final, coords).rgb ;
            pixel_out.rgb = float(BLOOM_BYPASS < 0.5) * pixel_out.rgb + bloomed;
        }

		//if (DO_VIGNETTE == 1.0) {
		//	vec2 sinco = cos((vTexCoord-0.5) / V_SIZE) ;
		//	pixel_out.rgb *= V_POWER * (sinco.y * sinco.x);
		//}
    return pixel_out.rgb;
}

void main() {
    
    #define RECT01 vec4(0, 0, 1, 1)
    float content_mask = float(is_first_inside_rect(vTexCoord, RECT01));
    vec2 co_content = vTexCoord;
    
    if (DO_CURVATURE == 1.0)  {
        co_content = Warp_koko(vTexCoord, vec2(GEOM_WARP_X, GEOM_WARP_Y*float(need_NO_integer_scale())), 0.5);
        content_mask = fn_border(co_content);
    }

    FragColor.rgb = vec3(0.0);
    if (content_mask > 0.0) {
        FragColor.rgb = fn_pixel_content(co_content) * content_mask;
        return;
    }
    
}
