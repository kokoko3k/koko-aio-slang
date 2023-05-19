#version 450

/* This pass:
 * Composes the previous passes
 * Does masks, spot, bezel, vignette, background image (anything else?)
 */


#define DEBUG_PRINT_VALUE 1.0
//#define DEBUG_QUAD_SPLIT  1.0
//#define DEBUG_DUAL_SPLIT  1.0

#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;


layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;
layout(location = 2) out vec2 spot_offset;

layout(location = 4) out float vIsRotated;


//Curvature:
    layout(location = 5) out vec2 vWarp_vexp;
    layout(location = 6) out vec2 vWarp_arg2;

//Scanlines:
    layout(location = 7) out float vIsInterlaced;
    layout(location = 9) out float vScanlinePeriod;
    layout(location = 10) out float vScanlineAlternateOffset;
    layout(location = 11) out float vMax_inLum;
    
//Vignette, spot:
    layout(location = 12) out float vIn_aspect;
    
layout(location = 13) out float vDynamicSeed;
layout(location = 14) out float vBEZEL_INNER_ZOOM_adapted;


layout(location = 17) out float vDo_Tate;
layout(location = 18) out vec3 vDotMat_Grid_Color;
layout(location = 19) out vec4 vPG_offsets_and_size;
layout(location = 20) out vec2 vPG_freq_base_screen;
layout(location = 21) out vec2 vPG_freq_base_screen_unfloored;
layout(location = 22) out vec2 vPG_period_multiplier;
layout(location = 23) out vec2 vPG_test_floor;
layout(location = 24) out vec2 vPG_OriginalSize_tated;
layout(location = 25) out vec2 vPG_OutputSize_tated;
layout(location = 26) out vec2 vPG_OutputCoord_tated;
layout(location = 27) out float vDotMat_Grid_Sharpness;
layout(location = 28) out float vfprintvalue;

#include "includes/functions.include.slang"

#define PI_15 4.71238898038469 //pi*1.5


vec2 get_zooms_modifier() {
    // This function is meant to live in vertex shader; its purpose is to
    // give the final scale factor by taking in consideration various zoom modifiers.
    //It works by calculating the new 0.0 and 1.0 coords then measuring the new distance between them

    // WARNING: This has to be in sync with the code, so everytime a scaling flow is modified, this needs to be updated. WARNING
    // WARNING: This has to be in sync with the code, so everytime a scaling flow is modified, this needs to be updated. WARNING
    // WARNING: This has to be in sync with the code, so everytime a scaling flow is modified, this needs to be updated. WARNING
    
    vec2 co_scaled_min = vec2(0.0);
    vec2 co_scaled_max = vec2(1.0);
        
    if ( need_NO_integer_scale() ) {
        co_scaled_min = get_scaled_coords_aspect(co_scaled_min, global.FinalViewportSize, vIn_aspect, bool(vIsRotated));
        co_scaled_max = get_scaled_coords_aspect(co_scaled_max, global.FinalViewportSize, vIn_aspect, bool(vIsRotated));
    } else {
        co_scaled_min = integer_scale(co_scaled_min, vIn_aspect, bool(vIsRotated), GAME_GEOM_INT_SCALE-1.0 ) + vec2( GAME_GEOM_OFF_FIX /10000);
        co_scaled_max = integer_scale(co_scaled_max, vIn_aspect, bool(vIsRotated), GAME_GEOM_INT_SCALE-1.0 ) + vec2( GAME_GEOM_OFF_FIX /10000);
    }
    
    
    co_scaled_min = (zoom(co_scaled_min + vec2(-GLOBAL_OFFX, -GLOBAL_OFFY), GLOBAL_ZOOM ) * DO_GLOBAL_SHZO) + 
                (co_scaled_min * (1-DO_GLOBAL_SHZO) );
    co_scaled_max = (zoom(co_scaled_max + vec2(-GLOBAL_OFFX, -GLOBAL_OFFY), GLOBAL_ZOOM ) * DO_GLOBAL_SHZO) + 
                (co_scaled_max * (1-DO_GLOBAL_SHZO) );
    
    if (DO_BEZEL == 1.0) {
        co_scaled_min = zoomout_coords(co_scaled_min, -vBEZEL_INNER_ZOOM_adapted , 1.0);
        co_scaled_max = zoomout_coords(co_scaled_max, -vBEZEL_INNER_ZOOM_adapted , 1.0);
    }
 	if (DO_GAME_GEOM_OVERRIDE == 1.0) {
		co_scaled_min = content_geom_override(co_scaled_min, GAME_GEOM_ASPECT, vIn_aspect, GAME_GEOM_VSHIFT, GAME_GEOM_HSHIFT, GAME_GEOM_ZOOM);
        co_scaled_max = content_geom_override(co_scaled_max, GAME_GEOM_ASPECT, vIn_aspect, GAME_GEOM_VSHIFT, GAME_GEOM_HSHIFT, GAME_GEOM_ZOOM);
    }
 
    //vfprintvalue = 1/(co_scaled_max.y - co_scaled_min.y);
    return 1 / vec2(co_scaled_max.x - co_scaled_min.x,
                co_scaled_max.y - co_scaled_min.y );
    
}

void main() {
    gl_Position = global.MVP * Position;
    vIsRotated = float(is_rotated());
    vIn_aspect = get_in_aspect();
    
    //Calculate vTexcoord as fractional or integer scaled?
        if ( need_NO_integer_scale() )
            vTexCoord = get_scaled_coords_aspect(TexCoord,global.FinalViewportSize, vIn_aspect, bool(vIsRotated));
        else
            vTexCoord = integer_scale(TexCoord, vIn_aspect, bool(vIsRotated), GAME_GEOM_INT_SCALE-1.0 ) + vec2( GAME_GEOM_OFF_FIX /10000);

    
    
    //if (DO_GLOBAL_SHZO >0.5)
    //    vTexCoord = zoom(vTexCoord + vec2(-GLOBAL_OFFX, -GLOBAL_OFFY), GLOBAL_ZOOM );
    //..unbranched previous
        vTexCoord = (zoom(vTexCoord + vec2(-GLOBAL_OFFX, -GLOBAL_OFFY), GLOBAL_ZOOM ) * DO_GLOBAL_SHZO) + 
                    (vTexCoord * (1-DO_GLOBAL_SHZO) );

    vOutputCoord = TexCoord ;


    vec2 vFragCoord = vec2( floor(vOutputCoord.x * params.OutputSize.x),
                            floor(vOutputCoord.y * params.OutputSize.y));

    vDo_Tate = float(TATE+vIsRotated > 1.001);

    vBEZEL_INNER_ZOOM_adapted = get_BEZEL_INNER_ZOOM() * DO_BEZEL;
    
    //Precalc some Curvature/Warp values:
        vWarp_vexp = 1.0/ (1 + (vec2(GEOM_WARP_X, GEOM_WARP_Y) * 0.2)) ;
        vWarp_arg2 = 1.0 - pow(vec2(0.29289321881345247559915563789515), vWarp_vexp );

    //SPOT
        spot_offset = offsets_from_float(S_POSITION+420.0,40);
        spot_offset = spot_offset / 10.0 + vec2(0.0,1.0);
        
    //Help scanline/pixelgrid code too:
        bool bIs_Interlaced = is_interlaced();
        vIsInterlaced = float(bIs_Interlaced);
            
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

        
    //Generate a seed that changes over time for temporal random noise
        vDynamicSeed = mod(params.FrameCount, 60.0001);


    //Calc dotmat grid color
        vDotMat_Grid_Color = vec3(DOT_M_G_BRT);
        if (DO_DOT_MATRIX + DO_CCORRECTION > 1.1) {
            vDotMat_Grid_Color = color_tools(vec3(DOT_M_G_BRT), kelvin2rgb(TEMPERATURE));
            //Since we modify grid brightness via a specific use parameter, explicitely multiply it by that:
                vDotMat_Grid_Color *= DOT_M_G_BRT ;
        }
            
    //Pixelgrid: get mask type; .rgb contains layout, .a contains the size.
        #define PG_H_COUNT vPG_offsets_and_size.a
        vPG_offsets_and_size = PG_get_hmask_preset() ;
        //scale offsets to be used by sin/cos:
            vPG_offsets_and_size.rgb *= (pi / PG_H_COUNT);

    //Pixelgrid: Calc freq_base_screen
        //Tate ?
            vPG_OutputSize_tated   = params.OutputSize.xy;
            vPG_OutputCoord_tated  = vOutputCoord.xy + vec2(0.00001);
            vPG_OriginalSize_tated = params.OriginalSize.xy;
            
            if (vDo_Tate == 1.0) {
                vPG_OutputSize_tated   = params.OutputSize.yx;
                vPG_OutputCoord_tated  = vOutputCoord.yx;
                vPG_OriginalSize_tated = params.OriginalSize.yx;
            }
                
            // screen coords needs flooring, but unfortunately floor() does not work well in vertex shader, so calc as mnuch as possible without floor()
                vPG_period_multiplier = vec2(PIXELGRID_MUL_X, PIXELGRID_MUL_Y);
                vPG_freq_base_screen = pi * vec2(1/PG_H_COUNT, 0.5);

            //the following unfloored coords are needed by sin/cos later to understand if we are on an even or odd mask
                vPG_freq_base_screen_unfloored = pi * vec2(1/PG_H_COUNT, 0.5) * (vPG_OutputCoord_tated * vPG_OutputSize_tated);
                
    //Pixelgrid: adapt period multiplier
        if (vPG_period_multiplier.x < 0.0) vPG_period_multiplier.x = 1/-vPG_period_multiplier.x;  
        if (vPG_period_multiplier.y < 0.0) vPG_period_multiplier.y = 1/-vPG_period_multiplier.y;            
    
    
    //Dot matrix: measure the final picture size to choose a right sharpness level
    //For simplicity and (my) mental health, take only y into account.
        vDotMat_Grid_Sharpness = DOT_M_G_SHARP;
        if (DOT_M_G_SHARP == 0.0) {
            float zooms_modifier  = get_zooms_modifier().y;
            float dotmat_insize  = global.flick_and_noise_passSize.y;
            float dotmat_outsize = global.FinalViewportSize.y  * zooms_modifier;
            vfprintvalue = dotmat_outsize / dotmat_insize;
            vDotMat_Grid_Sharpness = (dotmat_outsize / dotmat_insize);
            vDotMat_Grid_Sharpness = vDotMat_Grid_Sharpness * 3.6 - 3.1;
            vDotMat_Grid_Sharpness = clamp(vDotMat_Grid_Sharpness, 0.5, 20.0);
           
        }
}



#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 2) in vec2 spot_offset;

layout(location = 4) in float vIsRotated;
layout(location = 5) in vec2 vWarp_vexp;
layout(location = 6) in vec2 vWarp_arg2;
layout(location = 7) in float vIsInterlaced;

layout(location = 9) in float vScanlinePeriod;
layout(location = 10) in float vScanlineAlternateOffset;
layout(location = 11) in float vMax_inLum;
layout(location = 12) in float vIn_aspect;
layout(location = 13) in float vDynamicSeed;
layout(location = 14) in float vBEZEL_INNER_ZOOM_adapted;


layout(location = 17) in float vDo_Tate;
layout(location = 18) in vec3 vDotMat_Grid_Color;
layout(location = 19) in vec4 vPG_offsets_and_size;
layout(location = 20) in vec2 vPG_freq_base_screen;
layout(location = 21) in vec2 vPG_freq_base_screen_unfloored;
layout(location = 22) in vec2 vPG_period_multiplier;
layout(location = 23) in vec2 vPG_test_floor;
layout(location = 24) in vec2 vPG_OriginalSize_tated;
layout(location = 25) in vec2 vPG_OutputSize_tated;
layout(location = 26) in vec2 vPG_OutputCoord_tated;
layout(location = 27) in float vDotMat_Grid_Sharpness;
layout(location = 28) in float vfprintvalue;

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


float morph_shape_easy(float shape, float power, float steep ) {
    return pow(shape, 1/(power*2.0));
}


float morph_shape_05(float shape, float power, float steep ) {
    float lum_scaled = power;
    float l = lum_scaled; // (already clamped)
    float l1 = pow(l, 3) * 10;
    shape = pow(shape, 1/sqrt(l1));
    return shape;
}


float morph_shape_full(float shape, float power, float steep ) {
    float lum_scaled = power;
    float l = lum_scaled; // (already clamped)
    if (lum_scaled <= 0.5+steep) {
        float l1 = pow(l, 4) * 15;
        shape = pow(shape, 1/sqrt(l1));
    } else {
        float l2 = (l-0.5)*2.0;
        shape = mix(shape, 1.0, l2);    //shape = shape * (1-l2) + l2;
    }
    return shape;
}


vec3 morph_shape(vec3 shape, vec3 power, float steep ) {
    return vec3(
      morph_shape_full(shape.x, power.x, steep),
      morph_shape_full(shape.y, power.y, steep),
      morph_shape_full(shape.z, power.z, steep)
    );
}

float morph_shape(float shape, float power, float steep ) {
    return morph_shape_full(shape, power, steep);
}

float smoothstep_fast(float edge0, float edge1, float x) {
  return smoothstep(edge0,edge1,x);
  float t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  //return cos(t * 3.14159265358979323846) * -0.5 + 0.5;
  return mix(0.0, 1.0, t);
}

vec3 smoothstep_fast(vec3 edge0, vec3 edge1, vec3 x) {
  return smoothstep(edge0,edge1,x);
  vec3 t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  //return cos(t * 3.14159265358979323846) * -0.5 + 0.5;
  return mix(vec3(0.0), vec3(1.0), t);
}



vec4 fn_pixel_grid(vec2 in_coords, vec3 pixel_in, float min_inLum, float max_inLum) { 
    
    //Tate ? (other outputsize,originalsize and outputcoords "tated" in vertex shader.)
        if (vDo_Tate == 1.0) in_coords.xy = in_coords.yx;

      
    //Get preset masks on ".rgb" and mask size on ".a" , mask and period for every phosphor done in vertex shader.
        float PG_h_count = vPG_offsets_and_size.a; 
        vec3  PG_offsets = vPG_offsets_and_size.rgb;

        vec2 freq_base_core   = pi * in_coords * vPG_OriginalSize_tated ;

        //Screen coords:
            //screen coords needs flooring:
                vec2 period_multiply = vec2(PIXELGRID_MUL_X, PIXELGRID_MUL_Y);
                vec2 freq_base_screen = vPG_freq_base_screen * floor(vPG_OutputCoord_tated * vPG_OutputSize_tated * period_multiply ) / period_multiply;
//freq_base_screen = vPG_freq_base_screen * vPG_OutputCoord_tated * vPG_OutputSize_tated ;
            //the following unfloored coords are needed by sin/cos later to understand if we are on an even or odd mask
                //vec2 freq_base_screen_unfloored = pi * vec2(1/PG_h_count, 0.5) * (vPG_OutputCoord_tated * vPG_OutputSize_tated);  
                vec2 freq_base_screen_unfloored = vPG_freq_base_screen_unfloored; //<-- missing muls because done to vertex shader.

            
    //Switch between core and screen sizes (x and y)
        vec2 freq_base           = mix( freq_base_core, freq_base_screen,           vec2(PIXELGRID_SIZE_W, PIXELGRID_SIZE_H));
        vec2 freq_base_unfloored = mix( freq_base_core, freq_base_screen_unfloored, vec2(PIXELGRID_SIZE_W, PIXELGRID_SIZE_H));

        
    //Apply multiplier:
        freq_base /= vPG_period_multiplier;
        freq_base_unfloored /= vPG_period_multiplier;
        
        vec3 freq_rgb = vec3(freq_base.x) - PG_offsets;

    //Width phosphor mask:
        vec3 rgb_w = vec3(1.0);
        if (DO_PIXELGRID_W == 1.0) {
            //get 3 sines in black/white
                rgb_w = cos(freq_rgb);

            //make them always positive and double frequency:
                rgb_w = (rgb_w * rgb_w);

            //modulate each phosphor width according to input luminance
                vec3 phosphor_width = map_range(pixel_in, min_inLum, max_inLum, PIXELGRID_MIN_W, PIXELGRID_MAX_W);
                rgb_w = morph_shape(rgb_w, phosphor_width, PIXELGRID_NO_INTERBLEED_W);
        }
    
    //Height phosphor mask (can be used for scanlines, slotmask, aperturegrille):
        vec3 rgb_h = vec3(1.0);
        if (DO_PIXELGRID_H == 1.0 && !(PIXELGRID_INTR_DISABLE_Y==1.0 && vIsInterlaced==1.0)) {
            //calculate each phosphor eight according to input luminance 
                vec3 phosphor_height = map_range(pixel_in * rgb_w, min_inLum, max_inLum, PIXELGRID_MIN_H, PIXELGRID_MAX_H);
            //offset trias to emulate core level slotmask, calc right offset here:
                //sin() tell use if the current cell position is odd or even:
                    float o =  (pi/(PG_h_count*2.0));  
                    float sin_check_offset = sin(freq_base_unfloored.x + o);
                    float is_even = step(sin_check_offset, 0.0);
                
                //Then we can apply the optional offset to emulate the slotmask on even cells
                    float core_offset =  is_even * pi * PIXELGRID_OFFSET_CORE;
                
                //Since we can emulate scanlines, take into account current scanline phase:
                    float interlacing_adapt_period = vScanlinePeriod;
                    float interlacing_adapt_offset = vScanlineAlternateOffset;
                
            //get a single sine in black/white with applied the optional staggered offset for slotmask:
                float rgb_h_sin = sin(freq_base.y * interlacing_adapt_period + core_offset + interlacing_adapt_offset );
            //make it positve with doubled frequency:
                rgb_h_sin = (rgb_h_sin * rgb_h_sin);
                
            //Finally get 3 sines out of the previous one by applying height modifiers
                rgb_h = vec3(rgb_h_sin);
                rgb_h = morph_shape(rgb_h, phosphor_height, PIXELGRID_NO_INTERBLEED_H);
        }

    //Height phosphor mask number 2, can be used for slotmask,aperturegrille, not scanlines.
    //...well technically yes, but they would have a boxed shape.
        vec3 darklines_mask=vec3(1.0);
        if (PIXELGRID_Y_MASK > 0.0) {
            //offset trias to emulate core level slotmask, calc right offset here:
            //sin() tell use if the current cell position is odd or even:
                float o =  (pi/(PG_h_count*2.0));  
                float sin_check_offset2 = sin(freq_base_unfloored.x + o);
                float is_even2 = step(sin_check_offset2, 0.0);

            //Switch reference coords according to user pref: 
                float freq_cell_y = mix_step(freq_base_core.y, freq_base_screen.y, PIXELGRID_Y_MASK_COORDS);
                
            //mask phosphors heigth
                #define PH_MASK_HEIGHT (freq_cell_y * PIXELGRID_Y_MASK_HEIGHT)
            //phosphors mask stagger
                #define PH_MASH_OFFSET  (PIXELGRID_Y_MASK_OFFSET * pi * 0.5  )
                
            //Use abs(sin) (later 1-abs(sin) to get orizontal gaps, use pow to make them steep.
                float mask_shape = abs(cos(PH_MASK_HEIGHT  + (PH_MASH_OFFSET * is_even2))) ;
                mask_shape = pow(mask_shape, PIXELGRID_Y_MASK_STEEP);
                
            //Get per channel input luminance by clamping pixel_in and aplplying hmask
                vec3 lum=clamp(pixel_in * rgb_w, 0.0, 1.0);
            //Adapt the luminance effect via input parameter
                vec3 lum_adapted = (1-lum*PIXELGRID_Y_MASK_ON_WHITE);
            //Calc final mask visibility as the minimum between tha configured visibility and luminosity effect
                vec3 V=min( lum_adapted, vec3(PIXELGRID_Y_MASK) );
            //apply user visibility modifier to the mask
                darklines_mask=1-(mask_shape*V);
        }
     
    //Finally put width,height1 and height2 masks togheter:
        vec3 mask = rgb_w * rgb_h * darklines_mask;
        
    //Also apply mask to input pixel:
        vec3 pixel_masked = mask * pixel_in;
        vec3 pixel_out = mix(pixel_masked, mask, 0.0);
    //And return it with the alpha channel containing the mask itself, so that halo can selectively light it.
        return vec4(pixel_out, dot(mask, vec3(0.3333) ));
}


vec4 fn_pixel_dotmat(vec2 coords, vec3 pixel_in) {

    //Base angle, depends on original size:
        vec2 angle_base = coords * pi * params.OriginalSize.xy; //FIXME here we want .yy to make integer scaling

    //Zoom to debug:
        angle_base/=DOT_M_MULTIPLY;

    //Set the grid sharpness from vertex shader:
        float s_grid = vDotMat_Grid_Sharpness;
  
        
    //Generate bw grid:     
        vec2 grid = cos(angle_base);
        grid = grid * grid;
        grid = pow(grid, vec2(s_grid));
        grid = 1 - grid;


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
                 mix(vDotMat_Grid_Color, pixel_in, fgrid_adpt),
                 fgrid_adpt
               );

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
    

                                                                            
    pixel_bleed = pixel_in;
    
    vec3 pixel_out = pixel_in;

   
    float dot_mat_or_pixelgrid = 1.0; //init dot grid or scanline mask to 1.0
    
    //Pixel grid
        if (DO_PIXELGRID == 1.0) {
            vec4 pixel_grid = fn_pixel_grid(coords, pixel_out, 0.0, vMax_inLum);
            //grid mask only is needed by halo to selectively light the grid.
                dot_mat_or_pixelgrid = pixel_grid.a;
                pixel_out = pixel_grid.rgb;
        }
    //Dot mask
        if (DO_DOT_MATRIX == 1.0) {
            vec4 pixel_dotmat = fn_pixel_dotmat(coords, pixel_out);
            //grid mask only is needed by halo to selectively light the grid.
                dot_mat_or_pixelgrid = pixel_dotmat.a;
            //rgb channel goes to pixel_out
            pixel_out = pixel_dotmat.rgb;
            
        }
        
    //Halo
        vec3 pixel_haloed = vec3(0.0);;

        if (DO_HALO == 1.0 ) {
            pixel_haloed = texture(halo_pass,coords).rgb;
            //Halo only on scanlines:
            pixel_out += pixel_haloed * dot_mat_or_pixelgrid ;
            //Halo over scanlines gap too:
            pixel_out += pixel_haloed * (HALO_VS_SCAN) * (1 - dot_mat_or_pixelgrid) ;            
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
        
    //Mirror coords needs to be calculated here, before geom override, but after curvature.
    //It is still not perfect but a reasonable tradeoff by now.
        vec2 co_mirror = zoom(co_content, 1/BEZEL_REFL_ZOOMOUT_ROOM);
        
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
  
     

    //Debug functions: 
        #ifdef DEBUG_QUAD_SPLIT
            if ( vOutputCoord.x < 0.5  && vOutputCoord.y > 0.5 || vOutputCoord.x > 0.5  && vOutputCoord.y < 0.5 )
            pixel_out = texture(flick_and_noise_pass,vOutputCoord).rgb;
        #endif
    
        #ifdef DEBUG_DUAL_SPLIT
            if (vTexCoord.y < 0.5) pixel_out = texture(flick_and_noise_pass,vTexCoord).rgb;
        #endif
            
        #ifdef DEBUG_PRINT_VALUE
            float maxdigits = 10.0;
            float decimalplaces = 2.0;
            float fvalue = vfprintvalue;
            vec2 vFragCoord = vec2( floor(vOutputCoord.x * params.OutputSize.x),
                                floor(vOutputCoord.y * params.OutputSize.y));
            pixel_out += PrintValueVec3( vTexCoord, vFragCoord, fvalue, maxdigits, decimalplaces );
        #endif
        
 
    FragColor = vec4(pixel_out, 1.0);
   
    
}
