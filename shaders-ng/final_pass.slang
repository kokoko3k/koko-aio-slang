#version 450

/* This pass:
 * Composes the previous passes
 * Does masks, spot, bezel, vignette, background image (anything else?)
 */

                                #define DEBUG_TEXTURE Original
                                //#define DEBUG_TEXTURE colortools_and_ntsc_pass
//#define DEBUG_PRINT_VALUE
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
layout(location = 2) out vec2 spot_offset;
layout(location = 3) out float vIsRotated;
//Scanlines:
layout(location = 4) out float vIsInterlaced;
layout(location = 5) out float vScanlinePeriod;
layout(location = 6) out float vScanlineAlternateOffset;
layout(location = 7) out float vMax_inLum;
//Vignette, spot:
layout(location = 8) out float vIn_aspect;
//
layout(location = 9) out float vDynamicSeed;
layout(location = 10) out float vBEZEL_INNER_ZOOM_adapted;
layout(location = 11) out float vDo_Tate;
layout(location = 12) out vec3 vDotMat_Grid_Color;
layout(location = 13) out vec4 vPG_offsets_and_size;
layout(location = 14) out vec2 vPG_freq_base_screen;
layout(location = 15) out vec2 vPG_freq_base_screen_unfloored;
layout(location = 16) out vec2 vPG_period_multiplier;
layout(location = 17) out vec2 vPG_OriginalSize_tated;
layout(location = 18) out vec2 vPG_OutputSize_tated;
layout(location = 19) out vec2 vPG_OutputCoord_tated;
layout(location = 20) out float vDotMat_Grid_Sharpness;
layout(location = 21) out float vfprintvalue;
layout(location = 22) out float vPG_mask_height;
layout(location = 23) out float vDeltaRenderOk;
layout(location = 24) out float vDo_pixelgrid_h;
layout(location = 25) out float vDo_Curvature;
layout(location = 26) out float vPG_offsets_adjust_for_stagger;


layout(location = 31) out float I_am_a_placeholder_keep_reading;
//..to remind you that location = 31 is the last accepted by vulkan
//or Retroarch crashes or nvidia starts to give Xids.
//unsure if the issue is with retroarch or with vulkan specs.
//If in short, consider to pack more datas into vec2,3,4.
//But bear in mind that exceding the limit leads to 
//slowdowns.

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
    bool bIsRotated = is_rotated();
    vIsRotated = float(bIsRotated);
    
    if ( (TATE == 1.0 && bIsRotated) || TATE == 2.0)
        vDo_Tate = 1.0;
            else
        vDo_Tate = 0.0;
    //vDo_Tate = float(TATE+vIsRotated > 1.001); //<<-- reported problems with amd (?)
    
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



    vBEZEL_INNER_ZOOM_adapted = get_BEZEL_INNER_ZOOM() * DO_BEZEL;
    

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
                     max( 1.0, mix(1.0, IN_GLOW_POWER, DO_CCORRECTION));

        
    //Generate a seed that changes over time for temporal random noise
        vDynamicSeed = mod(params.FrameCount, 30.0001);


    //Calc dotmat grid color
        vDotMat_Grid_Color = vec3(DOT_M_G_BRT);
        if (DO_DOT_MATRIX + DO_CCORRECTION > 1.1) {
            vDotMat_Grid_Color = color_tools(vec3(DOT_M_G_BRT), kelvin2rgb(TEMPERATURE));
            //Since we modify grid brightness via a specific use parameter, explicitely multiply it by that:
                vDotMat_Grid_Color *= DOT_M_G_BRT ;
        }
            
    //Pixelgrid: get mask type; .rgb contains layout, .a contains the size.
        vPG_offsets_and_size = PG_get_hmask_preset() ;
        #define PG_H_COUNT vPG_offsets_and_size.a

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
                
            // screen coords needs flooring, but unfortunately floor() does not work well in vertex shader, so calc as much as possible without floor()
                vPG_period_multiplier = vec2(PIXELGRID_MUL_X, 1.0);
                vPG_freq_base_screen = pi * vec2(1/PG_H_COUNT, 0.5);

            //the following unfloored coords are needed by sin/cos later to understand if we are on an even or odd mask
                vPG_freq_base_screen_unfloored = pi * vec2(1/PG_H_COUNT, 0.5) * (vPG_OutputCoord_tated * vPG_OutputSize_tated);
              
  
        //This is needed to make sure even/odd staggering period matches betweeb floored (screen 1X)
        //and unfloored coords (core or non 1x mask size).
        //The issue visible when staggering the slotmask.           FIXME: Not yet 100% perfect
            vPG_offsets_adjust_for_stagger = 0.0;
            if (PIXELGRID_SIZE_W == 0.0 || PIXELGRID_MUL_X != 1.0) {
                //vec4 unfloored_offsets_fix = vec4(1.5,0.5,1.0,0.0);
                vec4 unfloored_offsets_fix = vec4(1.6, 0.81, 0.54, 0.81);
                //vPG_offsets_adjust_for_stagger = (pi*0.5)/PG_H_COUNT;
                vPG_offsets_adjust_for_stagger = unfloored_offsets_fix[int(PG_H_COUNT)-1];
            }


        //scale offsets to be used by sin/cos:
            vPG_offsets_and_size.rgb *= (pi / PG_H_COUNT);
                
    //Pixelgrid: adapt period multiplier
        if (vPG_period_multiplier.x < 0.0) vPG_period_multiplier.x = 1/-vPG_period_multiplier.x;  
        if (vPG_period_multiplier.y < 0.0) vPG_period_multiplier.y = 1/-vPG_period_multiplier.y;     
        
        
    //Pixelgrid: adapt mask height
        vPG_mask_height = PIXELGRID_Y_MASK_HEIGHT;
        if (vPG_mask_height < 0.0) vPG_mask_height = 1/-vPG_mask_height;
    
    //Pixelgrid: do horizontal if enabled, but skip it if user doesn't want it on interlaced content.
        vDo_pixelgrid_h = float(DO_PIXELGRID_H > 0.0 && !(PIXELGRID_INTR_DISABLE_Y==1.0 && vIsInterlaced==1.0));

       
    vDo_Curvature = DO_CURVATURE * (GEOM_WARP_X + GEOM_WARP_Y);
    
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
            vDotMat_Grid_Sharpness = clamp(vDotMat_Grid_Sharpness, 0.1, 20.0);
            //vfprintvalue = vDotMat_Grid_Sharpness;
        }
                                                                                               // Delta render, mandatory conditions:
    vDeltaRenderOk = float(  ( params.FrameCount % int(DELTA_RENDER_FORCE_REFRESH) != 0.0 ) && // - We are in a frame that is not forced for full refresh
                             ( vIsInterlaced != 1.0 || PIXELGRID_INTR_DISABLE_Y == 1.0 || DO_PIXELGRID_H == 0.0)   // - screen is not interlaced or we disabled scanlines on interlaced content
                           ); 
}



#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 2) in vec2 spot_offset;
layout(location = 3) in float vIsRotated;
layout(location = 4) in float vIsInterlaced;
layout(location = 5) in float vScanlinePeriod;
layout(location = 6) in float vScanlineAlternateOffset;
layout(location = 7) in float vMax_inLum;
layout(location = 8) in float vIn_aspect;
layout(location = 9) in float vDynamicSeed;
layout(location = 10) in float vBEZEL_INNER_ZOOM_adapted;
layout(location = 11) in float vDo_Tate;
layout(location = 12) in vec3 vDotMat_Grid_Color;
layout(location = 13) in vec4 vPG_offsets_and_size;
layout(location = 14) in vec2 vPG_freq_base_screen;
layout(location = 15) in vec2 vPG_freq_base_screen_unfloored;
layout(location = 16) in vec2 vPG_period_multiplier;
layout(location = 17) in vec2 vPG_OriginalSize_tated;
layout(location = 18) in vec2 vPG_OutputSize_tated;
layout(location = 19) in vec2 vPG_OutputCoord_tated;
layout(location = 20) in float vDotMat_Grid_Sharpness;
layout(location = 21) in float vfprintvalue;
layout(location = 22) in float vPG_mask_height;
layout(location = 23) in float vDeltaRenderOk;
layout(location = 24) in float vDo_pixelgrid_h;
layout(location = 25) in float vDo_Curvature;
layout(location = 26) in float vPG_offsets_adjust_for_stagger;




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
//layout(set = 0, binding = 10) uniform sampler2D shift_and_bleed_pass;
layout(set = 0, binding = 11) uniform sampler2D in_glow_pass;
layout(set = 0, binding = 12) uniform sampler2D halo_pass;
layout(set = 0, binding = 13) uniform sampler2D final_passFeedback;
layout(set = 0, binding = 15) uniform sampler2D DEBUG_TEXTURE;



#define RECT01 vec4(0.0, 0.0, 1.0, 1.0)
#define HALF_PI 1.5707963267949
#define QUARTER_PI 0.785398163397448

#include "includes/functions.include.slang"


vec2 vOutputCoord_adapted;
vec2 get_vOutputCoord_adapted() {
    return vOutputCoord_adapted;
}


vec3 fn_pixel_nightify(vec3 color_in, float strength, vec3 ambilight) {
    if (strength == 0.0) return color_in;
    
    color_in = clamp(color_in, 0.0, 1.0);
    
    vec3 color_hsv_in = rgb2hsv(color_in);
    
    //If there is an ambientlight, then the strangth has to be lowered:
        vec3 strength_vec3 = vec3(strength - ambilight);
        
    strength_vec3 = scale_to_range_vec3(strength_vec3, 0.0, 1.0); 
    
    vec3 color_hsv_min = color_hsv_in;
    color_hsv_min.yz = scale_to_range_vec2(color_hsv_min.yz, -0.1, 0.1); 

    vec3 color_rgb_min = hsv2rgb(color_hsv_min);
    
   
    vec3 pixel_out = mix(color_in, color_rgb_min, strength_vec3);

   //It could make sense to higher the contrast when ambient light hits the picture,
    //Maybe this could be used independently on the nightify feature?
    /*vec3 new_contrast = ambilight;
    vec3 new_brightness = ambilight*0.0;
    pixel_out = scale_to_range_vec3(pixel_out, -new_contrast, 1+new_contrast) + new_brightness;*/

    return pixel_out;
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

vec3 morph_shape_full_vec3(vec3 shape, vec3 l, float steep, float gamma ) {
    vec3 l_pow = pow(l,vec3(gamma));
    vec3 l2 = min(l_pow * 16, 1+steep);
    vec3 s1 = pow(shape, 1/sqrt(l2));
    vec3 s2 = (1-s1) * l_pow;
    return s1+(s2/(1+steep));
    
}

/*vec3 morph_shape_full_vec3(vec3 shape, vec3 l, float steep ) {
    vec3 l_pow = pow(l,vec3(4.2));
    vec3 l2 = l_pow * 16;
    l2 = clamp(l2, 0.0, 1+steep);
    vec3 s1 = pow(shape, 1/sqrt(l2));
    vec3 s2 = (1-s1) * l_pow;
    return s1+(s2/(l+steep));
}*/

/*vec3 morph_shape_full_vec3(vec3 shape, vec3 l, float steep ) {
    vec3 l_pow = pow(l,vec3(4.1));
    vec3 l2 = l_pow * 16;
    l2 = clamp(l2, 0.0,1.0);
    vec3 s1 = pow(shape, 1/sqrt(l2));
    vec3 s2 = (1-s1) * l_pow * (l*l);
    return s1+(s2/(1+steep));
}*/

vec3 morph_shape(vec3 shape, vec3 power, float steep, float gamma ) {
   return morph_shape_full_vec3(shape, power, steep, gamma);

    return vec3(    
      morph_shape_full(shape.x, power.x, steep),
      morph_shape_full(shape.y, power.y, steep),
      morph_shape_full(shape.z, power.z, steep)
    );
   
        
    //Use this to compare different methods
    if (params.FrameCount % 2 == 0.0)
        return morph_shape_full_vec3(shape, power, steep, gamma);
            else
    return vec3(    
      morph_shape_full(shape.x, power.x, steep),
      morph_shape_full(shape.y, power.y, steep),
      morph_shape_full(shape.z, power.z, steep)
    );
}

/*float morph_shape(float shape, float power, float steep ) {
    return morph_shape_full(shape, power, steep);
}*/




vec3 downsample( sampler2D tex, vec2 uv, vec4 sourcesize,  float sharpness_add ) {
    vec2 sharpness = vec2(1.0)+sharpness_add; 
    vec2 scale = sourcesize.xy * sharpness;
    
    vec2 iuv = floor(uv * scale);
    vec2 bottomleft  =    iuv;
    vec2 bottomright =  ( iuv + vec2(1.0,0.0)) / scale;
    vec2 topleft     =  ( iuv + vec2(0.0,1.0)) / scale;
    vec2 topright    =  ( iuv + vec2(1.0,1.0)) / scale;
        
    bottomleft /= scale;
   
    vec2 dist = (uv - bottomleft)*scale;
        
    vec3 bl = texture(tex, bottomleft).xyz   ;
    vec3 br = texture(tex, bottomright).xyz  ;
    vec3 tl = texture(tex, topleft).xyz      ;
    vec3 tr = texture(tex, topright).xyz     ;
    
    vec3 tA = mix( bl, br, dist.x );
    vec3 tB = mix( tl, tr, dist.x );
    return mix( tA, tB, dist.y );

}

vec3 downsample_x( sampler2D tex, vec2 uv, vec4 sourcesize, float sharpness_add ) {  
    
    float sharpness = 1.0+sharpness_add;
    
    vec2 scale = vec2(sourcesize.x * sharpness, 1.0);

    vec2 iuv = vec2( floor(uv.x * scale.x), uv.y);
       
    vec2 bottomleft  =    iuv;
    vec2 bottomright =  ( iuv + vec2(1.0,0.0)) / scale;
        
    bottomleft /= scale;
   
    vec2 dist = (uv - bottomleft)*scale;

    vec3 bl = texture(tex, bottomleft).xyz   ;
    vec3 br = texture(tex, bottomright).xyz  ;
   
    return mix( bl, br, dist.x );
    
}

vec3 smoothstep_fast(vec3 edge0, vec3 edge1, vec3 x) {

  vec3 t = clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
  //return cos(t * 3.14159265358979323846) * -0.5 + 0.5;
  return mix(vec3(0.0), vec3(1.0), t);
}

vec4 fn_pixel_grid(vec2 in_coords, vec3 pixel_in, float min_inLum, float max_inLum  ) {     
    /*
     This would provide an additional method to alter scanlines "inertia", but has a cost of 4fps
     when using smoothstep_fast and 13fps(!) when using standard smoothstep.
     It could replace glow_x for tight blurs.
    */
    
    ////vec3 lum_h =  downsample(in_glow_pass, in_coords, global.flick_and_noise_passSize, 0.0).rgb;
    //vec3 lum_h =  downsample_x(in_glow_pass, in_coords, global.flick_and_noise_passSize, 0.0).rgb;  
    //lum_h *= smoothstep_fast( vec3(SERVICE1-0.1) ,vec3(SERVICE1), lum_h);
    //pixel_in = max(pixel_in, lum_h);
    
   
    //Scanlines: compute each phosphor height according to input luminance, puttin it here helpas parallelism a bit.
        float extragain_h = max(PIXELGRID_MAX_H, 1.0); //Handle 
        vec3 phosphor_height = map_range(pixel_in*extragain_h, min_inLum, max_inLum, PIXELGRID_MIN_H, clamp(PIXELGRID_MAX_H, PIXELGRID_MIN_H, 1.0));   
    
    
    //Tate ? (other outputsize,originalsize and outputcoords "tated" in vertex shader.)
        if (vDo_Tate == 1.0) in_coords.xy = in_coords.yx;
    //in_coords = in_coords - global.flick_and_noise_passSize.zw*0.5; //<-- needed if for whatever reason you want to draw scanlines and vgaps in first_pass
      
    //Get preset masks on ".rgb" and mask size on ".a" , mask and period for every phosphor done in vertex shader.
        float PG_h_count = vPG_offsets_and_size.a; 
        vec3  PG_offsets = vPG_offsets_and_size.rgb;

        vec2 freq_base_core = pi * in_coords * vPG_OriginalSize_tated ;

        //Screen coords:
            //The following unfloored coords are needed by sin/cos later to understand if we are on an even or odd mask
                //vec2 freq_base_screen_unfloored = pi * vec2(1/PG_h_count, 0.5) * (vPG_OutputCoord_tated * vPG_OutputSize_tated);
                vec2 freq_base_screen_unfloored = vPG_freq_base_screen_unfloored; //<-- missing muls because done to vertex shader.
        
            //Screen coords needs flooring, but we need to disable flooring if using non 1x screen coords
            // y screen coords appear to work just fine even if we always floor them,
            // you can use "float(fract(1/vPG_mask_height) < 0.01"as the y mix parameter instead of 1.0 if in doubt.
                #define SCREEN_Y_MIX 1.0 //<-- Always floor screen y coords (seems to work good everytime)
                //#define SCREEN_Y_MIX float(fract(1/vPG_mask_height) < 0.01) //<-- only floor screen y coords when non integer multipliers
                vec2 freq_base_screen = mix( vPG_freq_base_screen_unfloored, 
                                             vPG_freq_base_screen * floor(vPG_OutputCoord_tated * vPG_OutputSize_tated ),
                                             vec2( float(PIXELGRID_MUL_X==1.0), SCREEN_Y_MIX )
                                            );
                
    //Switch between core and screen sizes (x and y)
        vec2 freq_base           = mix( freq_base_core, freq_base_screen,           vec2(PIXELGRID_SIZE_W, 0.0));
        vec2 freq_base_unfloored = mix( freq_base_core, freq_base_screen_unfloored, vec2(PIXELGRID_SIZE_W, 0.0));

        
    //Apply multiplier:
        freq_base /= vPG_period_multiplier;
        freq_base_unfloored /= vPG_period_multiplier;
        
        vec3 freq_rgb = vec3(freq_base.x) - PG_offsets;

        
    //The following is needed by scanlines and vertical mask
    //sin() tell use if the current cell position is odd or even:

        //FIXME: is_even should be a single phosphor property.
        //If i manage to find a way to do it, i could use 
        //decon_stagger.r,g,b to stagger single phosphors.
        //And that way, i could blend staggered triads together
        //without "cuts" between them.
        //FIXME FIXME: Unsurer if the previous statement is still valid.
        
    //Moving it up there provides a small speed up due to
    //increased parallalism, I guess.
        float sin_check_offset = sin(freq_base_unfloored.x + vPG_offsets_adjust_for_stagger);
        float is_even = step(sin_check_offset, 0.0);

        
    //Scanlines and fake slotmask =========================================================================
        vec3 rgb_h = vec3(1.0);
        float dedot_mix_inverted = 1.0;

        //Pixelgrid: do horizontal if enabled, but skip it if user doesn't want it on interlaced content.
        //if (DO_PIXELGRID_H > 0.0 && !(PIXELGRID_INTR_DISABLE_Y==1.0 && vIsInterlaced==1.0)) { //103.1
        if (vDo_pixelgrid_h > 0.5) {

            //Since we emulate scanlines, take into account current scanline phase:
                float interlacing_adapt_period = vScanlinePeriod;

            //We can offset trias to emulate fake core level slotmask by applying the optional offset to emulate the slotmask on even cells
                float triad_stagger_offset =  is_even * pi * (PIXELGRID_OFFSET_CORE);
            //get 3 sines with applied the optional staggered offset for slotmask, and single phosphors staggering for y deconvergence.
                vec3 decon_stagger = vec3( PIXELGRID_DECON_R_H, PIXELGRID_DECON_G_H, PIXELGRID_DECON_B_H) ; //* (pixel_in/max_inLum) ;
                vec3 rgb_h_sin = sin( (freq_base_core.y * interlacing_adapt_period) + triad_stagger_offset - decon_stagger + vScanlineAlternateOffset );
            //make it positve with doubled frequency:
                rgb_h_sin = (rgb_h_sin * rgb_h_sin);
                        
            //Compute dedot mix here for use in h mask and vmask2 later             
                dedot_mix_inverted = (1-rgb_h_sin.r) * PIXELGRID_H_DEDOT ;
                dedot_mix_inverted = dedot_mix_inverted * (max(max(pixel_in.r, pixel_in.g), pixel_in.b)/max_inLum);
                //dedot_mix_inverted = dedot_mix_inverted * dot(pixel_in, vec3(0.33333) )/max_inLum;
                dedot_mix_inverted = 1-dedot_mix_inverted;
            
            // Compute each phosphor height according to input luminance, 
            // Moved outside the branch to help parallelism a bit
                //float extragain_h = max(PIXELGRID_MAX_H, 1.0); //Handle 
                //vec3 phosphor_height = map_range(pixel_in*extragain_h, min_inLum, max_inLum, PIXELGRID_MIN_H, clamp(PIXELGRID_MAX_H, PIXELGRID_MIN_H, 1.0));
                
                
            //Finally get 3 sines out of the previous one by applying height modifiers            
                rgb_h = morph_shape(rgb_h_sin, phosphor_height, PIXELGRID_NO_INTERBLEED_H, PIXELGRID_GAMMA_H);
                
                rgb_h = mix(vec3(1.0), rgb_h, DO_PIXELGRID_H);
                rgb_h = clamp(rgb_h, 0.0,1.0);
                
                
             /*   float punch_y = sin(freq_base_core.y);
                punch_y = pow(punch_y,32.0);
                float punch_x = sin(freq_base.x);
                punch_x = pow(punch_x,32.0);
                rgb_h +=vec3(punch_x * punch_y ) * SERVICE1 * 50;
                //return vec4(punch_x * punch_y );*/
                
                //Scanline "mangler"
                    //float t = 0.2;
                    //t = - (-0.6 * 0.3 - 0.12);
                    //t = 0.3;
                    //float t = SERVICE1;
                    //rgb_h = smoothstep(t, t+0.2, phosphor_height) * rgb_h;
                
                //Mask Gamma "out"
                    //rgb_h = pow(rgb_h, vec3(PIXELGRID_GAMMA_OUT_H));
                    //if (phosphor_height.r < 0.1) rgb_h = vec3(0.0);
        }
        

        
    //Horizontal Triad Mask: ||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
        vec3 rgb_w = vec3(1.0);
        vec3 rgb_grille = vec3(0.0);
        
        if (DO_PIXELGRID_W > 0.0) { //4%
            //get 3 sines in black/white
                rgb_w = cos(freq_rgb);
            //make them always positive and double frequency:
                rgb_w = (rgb_w * rgb_w);
            //"export" naked vertical grille
               rgb_grille = (rgb_w * rgb_w) * (rgb_w * rgb_w);
            //Scale Max width according to pre-gains:
                vec3 phosphor_width = map_range(pixel_in, min_inLum, max_inLum, PIXELGRID_MIN_W, PIXELGRID_MAX_W);
            //Get final phosphor width:
                rgb_w = morph_shape(rgb_w, phosphor_width, PIXELGRID_NO_INTERBLEED_W, PIXELGRID_GAMMA_W); //2%
            
            //Dedot rgb mask between h mask.
            //This work only when there are dots and have the countereffect when there are not.
            //This happen because flattening the rgb mask will make unflattened rgb triads
            //more evident, so this has to be used only when needed.    
                //rgb_w = mix(rgb_h, rgb_w, dedot_mix_inverted);
                rgb_w = mix(phosphor_width, rgb_w, dedot_mix_inverted);
                               
            //lower strength via user parameter?
                rgb_w = mix(vec3(1.0), rgb_w, DO_PIXELGRID_W);
        }
                    
    //1%
        //Mask strength modifiers for hmask, performs way better outside the main if then ^^ up there ^^

        /*     
            vec3 rgb_w_weakness = (pixel_in * PIXELGRID_HMASK_NO_BRIGHT) ;
            rgb_w_weakness = clamp(rgb_w_weakness,0.0,1.0);
            
            rgb_w = mix( rgb_w, vec3(1.0), rgb_w_weakness);
            rgb_w = mix( vec3(1.0), rgb_w, DO_PIXELGRID_W);
            //The following should be equivalent to ^ ^ but it seems slower.
            //    rgb_w = mix( vec3(1.0), rgb_w, DO_PIXELGRID_W * (1-rgb_w_weakness)  );
        */

    //Vertical mask .:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.:.
    // can be used for slotmask,aperturegrille, not scanlines.
    //...well technically yes, but they would have a boxed shape.
        vec3 darklines_mask=vec3(1.0);
        float PG_spark;
        vec3 pixel_in_unsparkled = pixel_in;
        if (PIXELGRID_Y_MASK > 0.0) {
            //Switch reference coords according to user pref: 
                float freq_cell_y = mix(freq_base_core.y,  freq_base_screen.y, PIXELGRID_Y_MASK_COORDS);

            //mask phosphors heigth
                #define PH_MASK_HEIGHT (freq_cell_y * vPG_mask_height)
            //phosphors mask stagger
                #define PH_MASH_OFFSET  (PIXELGRID_Y_MASK_OFFSET * pi * 0.5 )
                
            //Use abs(cos) (later 1-abs(cos) to get horizontal gaps, use pow to make them steep.
            //Stagger them by PH_MASH_OFFSET on even triads
                
                float mask_shape = abs(cos(  PIXELGRID_Y_MASK_SHIFT*pi +   PH_MASK_HEIGHT  + (PH_MASH_OFFSET * is_even)) ) ;
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
                vec3 lum=clamp(pixel_in * rgb_w, 0.0, 1.0);
            //Adapt the luminance effect via input parameter
                vec3 lum_adapted = (1-lum*PIXELGRID_Y_MASK_ON_WHITE);
            //Calc final mask visibility as the minimum between tha configured visibility and luminosity effect
                vec3 V=min( lum_adapted, vec3(PIXELGRID_Y_MASK) );
            //apply user visibility modifier to the mask
                darklines_mask = 1-(mask_shape*V);
            //Try to get a more brillant/sparkling look by highering the darklines
            //effect (sub) and pushing the source color, useful for slotmasks.
                PG_spark = PIXELGRID_Y_SPARK * PIXELGRID_Y_MASK;
                darklines_mask -= PG_spark;
                                
                pixel_in *= 1 + ((PG_spark*4) * dedot_mix_inverted);
                
            //Dedot darklines mask:
                darklines_mask = mix(vec3(1.0), darklines_mask, dedot_mix_inverted );
        }


    //Finally put H mask, Scanlines and darklines masks togheter:
        //vec3 mask = rgb_w * rgb_h * darklines_mask;
        vec3 mask = min( (rgb_w * rgb_h), darklines_mask * rgb_h); //<- this way it does not interfree with scanline height!
        //FIXME: test with coore or fuzzy coords how it works when using variable width phosphors, maybe 
        //it would need to be: vec3 mask = min((rgb_w * rgb_h), darklines_mask * rgb_h * rgb_w); =

    
    //mask posterization experiment:
        //mask = floor(mask*16.0)/16.0;
        //mask = pow(mask, vec3(0.5));
        

    
    //Apply Overmask:
        mask = PIXELGRID_OVERMASK * (mask - 0.5) + 0.5;
        pixel_in = mix(pixel_in, pixel_in * PIXELGRID_OVERMASK, PIXELGRID_OVERMASK);
  
    
    //Apply the mask to pixel_in and clamp the minimum to the unexcited grille.
    vec3 mask_and_grille = max(mask * pixel_in, rgb_grille * PIXELGRID_BASAL_GRID*0.0025);


    //return it with alpha channel containing the mask itself, so that halo can selectively light it.
    return vec4( mask_and_grille , dot(rgb_h, vec3(0.3333)));
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


float pixel_blank_alternate(float strength) {
    /*
             vec3 pixel_strobe = pixel_out.rgb * mod(params.FrameCount, 2);
                float max_c = max(pixel_out.r, max(pixel_out.g, pixel_out.b));
                float max_c_adpt = 1 - (max_c * 0.5);
                pixel_out.rgb = mix (pixel_out.rgb, pixel_strobe, ALT_BLANK_STRENGTH *    max_c_adpt       )   ;
    */
    
    // Emulate the low crt persistance by only drawing odd/even lines
    // on odd/even frames
    

    
    float line = vTexCoord.y * params.OutputSize.y;
    float l_period_half = ALT_BLANK_PERIOD / 2;
    
    
    //Use another alg that affects less dark colors for negative strength values.
   /* if (strength < 0.0) {
        strength *= -1;
        float max_c = max(source.r, max(source.g, source.b));
        float max_c_adpt = 1 - (max_c * 0.5);
        strength *= max_c_adpt;
    }*/
    
    //If the frame has been completely blanked, rendered will be 0.0
    //rendered will be returned and can be used to skip 
    float rendered;
    
    if  (mod(float(params.FrameCount),2.0  ) == 1) {
        if  (mod(line,ALT_BLANK_PERIOD) > l_period_half) {
            return strength;
        }
    } else {
        if  (mod(line,ALT_BLANK_PERIOD) <= l_period_half) {
            return strength;
        }
    }
    return 1.0;
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

vec3 light_over_image(vec3 light, vec3 image, float black_illumination) {
    //Simulates illumination.
    //It works by adding the light on the image.
    //It will add less light on dark colors (
    vec3 light_on_black = black_illumination * light;
    return image.rgb +  ( (light - light_on_black ) * image.rgb ) + light_on_black;
    
}

vec3 ambi_blend_image(vec4 image, vec3 ambi, float blend_mode) {
    //mix or add ambient light with image, also allow force colorization in add mode.
    if (DO_AMBILIGHT == 0.0) return image.rgb;
    
    // Fake a transparent image when force colorization is requested
    // So that we can use the same code used for alpha blend.
    // Also multiply AMBI_BG_IMAGE_FORCE * AMBI_BG_IMAGE_BLEND_MODE to skip
    // force colorization when mode blend mode is not "ADD".
        float image_alpha_adapted = image.a - (AMBI_BG_IMAGE_FORCE * AMBI_BG_IMAGE_BLEND_MODE);

    if (AMBI_BG_IMAGE_BLEND_MODE == 0.0) {
        image.rgb = mix(ambi.rgb, image.rgb, image_alpha_adapted);
    } else {
        //image.rgb =  image.rgb + (ambi.rgb * (1 - image_alpha_adapted)); 
        /*float light_on_black = 0.3;
        vec3 ambi_alpha_masked = ambi.rgb *  (1 - image_alpha_adapted);
        vec3 ambi_on_black = light_on_black * ambi_alpha_masked;
        
        image.rgb = image.rgb +  ((ambi_alpha_masked-ambi_on_black) * image.rgb) + ambi_on_black;*/
        
        float black_illumination = 0.5;
        vec3 ambi_alpha_masked = ambi.rgb *  (1 - image_alpha_adapted);
        image.rgb = light_over_image(ambi_alpha_masked, image.rgb, AMBI_ADD_ON_BLACK) ;
        
    }
    return image.rgb;
    
    /*image.rgb = (AMBI_BG_IMAGE_BLEND_MODE == 0.0) ? 
        mix(ambi.rgb, image.rgb, image_alpha_adapted) 
            : 
        image.rgb + (ambi.rgb * (1 - image_alpha_adapted)); 
        
    return image.rgb;*/
}

float gaussian_coefficient(float x, float sigma) {
    //restituisce un coefficiente gaussiano per x compreso tra 0 ed 1
    float coefficient = 1.0 / sqrt(2.0 * 3.14159265358979323846 * sigma);
    float exponent = -((x * x) / (2.0 * sigma));
    return coefficient * exp(exponent);
}




vec3 fn_pixel_content(vec2 coords) {
    
    vec3 pixel_out;    
    vec3 pixel_glowed;
    float dot_mat_or_pixelgrid = 1.0; //init dot grid or scanline mask to 1.0
    
    //Black frame insertion, made static, enable it in config.inc.
        #ifdef ALLOW_ALT_BLANK
            float alt_blank_power = 1.0;
            //Calculate if line has to be blanked
                if (DO_ALT_BLANK == 1.0 ) alt_blank_power = pixel_blank_alternate( 1 - ALT_BLANK_STRENGTH);
            
            //If we completely blanked the line, there is no need to process it further.
                if (alt_blank_power == 0.0) return vec3(0.0);
        #endif
    
    //#define USE_QUILEZ
    
    #ifdef USE_QUILEZ
        pixel_glowed = texture(in_glow_pass, coords_QULEZ(coords, global.flick_and_noise_passSize)).rgb;
        pixel_out = pixel_glowed;
    #else
        pixel_glowed = texture(in_glow_pass, coords).rgb;
        pixel_out = pixel_glowed;
    #endif
    
    
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
    /*    if (DO_BLOOM == 1.0 ) {
            vec3 bloomed=texture(bloom_pass_final, coords).rgb ;
            if (BLOOM_BYPASS != 1.0 ) {
                vec3 lum = clamp(pixel_glowed, 0.0,1.0);
                vec3 darkness=(1-lum) * (1-lum);
                bloomed = mix( bloomed * darkness , bloomed, BLOOM_OVER_WHITE);
            }
            pixel_out = bloomed + float(BLOOM_BYPASS < 0.5) * pixel_out;
        }*/
    //Bloom
        if (DO_BLOOM == 1.0 ) {
            vec3 bloomed=texture(bloom_pass_final, coords).rgb ;
            pixel_out = bloomed + float(BLOOM_BYPASS < 0.5) * pixel_out;
        }
            
    //Black frame insertion, made static, enable it in config.inc.
        #ifdef ALLOW_ALT_BLANK
            if (DO_ALT_BLANK == 1.0 )
                //apply the blank power we calculated earlier in the code.
                pixel_out.rgb = clamp(pixel_out.rgb,0.0,1.0) *  alt_blank_power;
        #endif
    
    return pixel_out;
}


vec4 fn_pixel_bezel(vec2 coords_for_bezel, vec2 coords_for_mirror, float nightify_str, vec3 pixel_ambilight) {
    
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
    
    float lut_specular = bezel_in.g * BEZEL_SPCL_STRENGTH;
    float reflection_modifier = 0.0;
    vec4 pixel_mirrored = vec4(0.0);
    
    // Calculate Reflections, can be skipped if blue channel is 0:
        if (bezel_in.b > 0.0) {
        //Reflections: Calculate the bezel roughness to apply to the reflecting area. (bezel_in.g expresses the specularity)
            float roughness = random_fast( 1/1080.0 * BEZEL_ROUGHNESS, vTexCoord );
            roughness *=  (1 - min(lut_specular * 10, 1.0)); // <-roughness over specular area looks bad.
            
        //Reflections:
            reflection_modifier = bezel_in.b; //bezel_in.b expresses how much the area is reflective
            
            //Sample the reflection pass with small offset to simulate the roughness
                pixel_mirrored = texture(reflected_blurred_pass, coords_for_mirror + roughness);
                float fcorners_shade = 1 - corners_shade(coords_for_bezel, 1.0) * BEZEL_CORNER_DARK;
                
            //Show less reflections in the corners
                pixel_mirrored.rgb *= fcorners_shade;

            //Push it over the specular areas and apply the reflection modifier
                pixel_mirrored.rgb = pixel_mirrored.rgb * (1 + lut_specular);

        }

    //Yes, we already passed ambilight as parameter, but if geometry content is overridden
    //then ambientlight may have not been sampled yet due to some skip logic made in the main()
        if (DO_AMBILIGHT == 1.0)
            pixel_ambilight = texture(ambi_temporal_pass, vOutputCoord).rgb;

    //Apply nightification, the strength is modulated by ambient light.
        //Use a shaded box to apply ambilight on external borders only
            float ambi_colorize_shade = create_ambi_colorize_shade(coords_for_bezel);


            vec3 ambi_over_bezel =  ( (AMBI_OVER_BEZEL * pixel_ambilight) *
                                    (bezel_in.a * ambi_colorize_shade) *
                                    (1-reflection_modifier) );
        
        bezel_out.rgb = fn_pixel_nightify(bezel_out.rgb, nightify_str, ambi_over_bezel )   ;

    
    //Apply reflections
            bezel_out += (pixel_mirrored.rgb * reflection_modifier);
        
        //Apply ambient light over the bezel        
            //bezel_out = bezel_out + ambi_over_bezel;
            bezel_out = light_over_image(ambi_over_bezel, bezel_out, AMBI_ADD_ON_BLACK);
        
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
        if (vDo_Curvature > 0.0) {
            co_content = Warp_koko(co_content, vec2(GEOM_WARP_X, GEOM_WARP_Y), 0.5); 
        }
        
    //Mirror coords needs to be calculated here, before geom override, but after curvature.
    //It is still not perfect but a reasonable tradeoff by now.
        vec2 co_mirror = zoom(co_content, 1/BEZEL_REFL_ZOOMOUT_ROOM);
        
    //Apply other content coords modifiers
        if (DO_GAME_GEOM_OVERRIDE == 1.0)
            co_content = content_geom_override(co_content, GAME_GEOM_ASPECT, vIn_aspect, GAME_GEOM_VSHIFT, GAME_GEOM_HSHIFT, GAME_GEOM_ZOOM);

    //Dynamic lum dependant full screen zoom?
        if (DO_DYNZOOM == 1.0)
            co_content = zoom(co_content, get_dyn_zoom(avglum_pass) );

    
    //Create an alpha mask to write content into, it holds opacity info that will be used to compose:
        if (DO_CURVATURE == 1.0)  {
            canvas_busy = fn_border(co_content);
        } else {
            canvas_busy = float(is_first_inside_rect(co_content, RECT01)); //FIXME: is step() faster?
        }

    if (DELTA_RENDER == 1.0) {
        bool reuse_old =  bool( texture(in_glow_pass, co_content).a * canvas_busy * vDeltaRenderOk ) ;
        if (reuse_old) {
            FragColor = texture(final_passFeedback, vOutputCoord) ;
            return;
        }
    }
              
    vec3 pixel_ambi = vec3(0.0);
    vec3 pixel_under_content = vec3(0.0);
    //Draw content only over the alpha mask, and sample ambientlight outside it to spare gpu cycles.
        if (canvas_busy > 0.5) {
            pixel_out = fn_pixel_content(co_content) * canvas_busy;
        } else {
            
            //Can we halve refresh rate in the outside border to spare some cycles?
            if ( HALVE_BORDER_UPDATE == 1.0 ) {
                if ((params.FrameCount % 2) != 1.0) {
                    pixel_out = texture(final_passFeedback, vOutputCoord).rgb;
                    FragColor = vec4(pixel_out, 1.0);
                    return;
                }
            }
            
            //Ambient light
            if (DO_AMBILIGHT == 1.0) {
                pixel_ambi = texture(ambi_temporal_pass, vOutputCoord).rgb;
                pixel_ambi += random_fast( (NOISEPOWER * NOISEPOWER_AMBI_MUL) * ((1-pixel_ambi.g) * (pixel_ambi.g*1 - pixel_ambi.r*0.125 -pixel_ambi.b*0.125  )    ) , 
                vTexCoord * vDynamicSeed  ) ;
            
                float  ambi_noise_power = (NOISEPOWER * NOISEPOWER_AMBI_MUL * (1-pixel_ambi.g) ) * //only middle green channel
                                          dot( pixel_ambi, vec3(-0.5,1.0,-0.5) );                  //denoise only greenish colors
                pixel_ambi += random_fast( ambi_noise_power, vTexCoord * vDynamicSeed  ) ;
                
                pixel_under_content = pixel_ambi * (1-canvas_busy);
            }
        }
    
    //This represents the inner bezel alpha (when using bezel) 
    //or the pixel_content canvas (when not using bezel)
    //It is used to draw spot on the whole inner tube even when toe content does not
    //fill the whole tube.
        float canvas_bezel_screen = canvas_busy; 
    
    //Draw Bezel
        vec4 pixel_bezel;
        //SKIP LOGIC is inside fn_pixel_bezel
        if (DO_BEZEL == 1.0) {
            pixel_bezel = fn_pixel_bezel(co_bezel, co_mirror, BG_IMAGE_NIGHTIFY, pixel_ambi);
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
                
                //Intersect rect_bezel and bezel alpha to get the inner tube alpha
                canvas_bezel_screen = (1 - pixel_bezel.a) * rect_bezel;
        }

    if (canvas_bezel_screen > 0.5) {
        //Vignette
            float vignette = 1.0;
            if (DO_VIGNETTE == 1.0) {
                //float dist = length(vec2((co_content.x-0.5)*vIn_aspect, co_content.y-0.5));
                //vignette = smoothstep(V_SIZE,0.0,dist)*V_POWER;
                vec2 sinco = (co_content-0.5) / V_SIZE ;
                vignette = cos(sinco.x) * cos(sinco.y) * V_POWER;
            } 
            
        //Spot
            float spot = 0.0;
            if (DO_SPOT == 1.0) {
                    float dist = length(vec2((co_content.x-0.5)*vIn_aspect, co_content.y-0.5)+spot_offset);
                    spot = smoothstep(S_SIZE,0.0,dist)*S_POWER;
            }

            float spot_vignette_noise = 0.0;
            if (DO_VIGNETTE + DO_SPOT > 0.0) {
                spot_vignette_noise = random_fast(NOISEPOWER, vOutputCoord ) ;
            }
        
            pixel_out = (pixel_out*vignette) + (spot + spot_vignette_noise)*canvas_bezel_screen;
        
    }
        //Background image have, no need to paint if not in the outer border:
            if (DO_BG_IMAGE == 1.0 && BG_IMAGE_OVER == 0.0 && canvas_busy < 1.0) {
                vec4 pixel_bg_image = fn_pixel_fgbg_image(bg_under);
                
                                                        //pixel_bg_image.rgb = scale_to_range_vec3(pixel_bg_image.rgb, -pixel_ambi, 1+pixel_ambi);
                vec3 anti_nightify_ambi = (pixel_ambi * AMBI_BG_IMAGE_BLEND_MODE) *
                                           max(AMBI_BG_IMAGE_FORCE, 1-pixel_bg_image.a) ;
                                           
                
                pixel_bg_image.rgb = fn_pixel_nightify(pixel_bg_image.rgb, BG_IMAGE_NIGHTIFY, anti_nightify_ambi );
                pixel_bg_image.rgb = ambi_blend_image(pixel_bg_image, pixel_ambi, AMBI_BG_IMAGE_BLEND_MODE);    
    
                pixel_under_content = pixel_bg_image.rgb;
            }
            

        //Smooth the image corners: canvas_busy (the alpha mask) is a white rect with shaded borders.
            pixel_out = mix (pixel_under_content, pixel_out, canvas_busy);
 
          
        //Backdrop
            if (DO_BACKDROP == 1.0)
                pixel_out += pixel_backdrop_image();

            
        //Foreground image
            if (DO_BG_IMAGE + BG_IMAGE_OVER == 2.0) {
                vec4 pixel_fg_image = fn_pixel_fgbg_image(bg_over);
                // if geometry content is overridden, ambientlight may have not been sample yet due to some skip logic
                if (DO_AMBILIGHT == 1.0 && (pixel_fg_image.a+AMBI_BG_IMAGE_FORCE) > 0.0 )
                    pixel_ambi = texture(ambi_temporal_pass, vOutputCoord).rgb;

                vec3 anti_nightify_ambi = (pixel_ambi * AMBI_BG_IMAGE_BLEND_MODE) *
                                           max(AMBI_BG_IMAGE_FORCE, 1-pixel_fg_image.a) ;
                
                pixel_fg_image.rgb = fn_pixel_nightify(pixel_fg_image.rgb, BG_IMAGE_NIGHTIFY, anti_nightify_ambi );
                
                pixel_out = mix(pixel_out, pixel_fg_image.rgb, pixel_fg_image.a);
                
                if (DO_AMBILIGHT + AMBI_BG_IMAGE_BLEND_MODE == 2.0) { 
                    float ambi_mask = create_ambi_colorize_shade(co_bezel);
                    float fg_image_alpha_adapted = max(pixel_fg_image.a - AMBI_BG_IMAGE_FORCE, 0.0);
                    //pixel_out = pixel_out + (pixel_ambi.rgb * (ambi_mask) * (1- fg_image_alpha_adapted));
                    vec3 light = pixel_ambi.rgb * (ambi_mask) * (1- fg_image_alpha_adapted);
                    pixel_out = light_over_image(light, pixel_out, AMBI_ADD_ON_BLACK);
                }
            }
  

    //Debug functions: 
        #ifdef DEBUG_QUAD_SPLIT
            if ( vOutputCoord.x < 0.5  && vOutputCoord.y > 0.5 || vOutputCoord.x > 0.5  && vOutputCoord.y < 0.5 )
            pixel_out = texture(DEBUG_TEXTURE,vOutputCoord).rgb;
        #endif
    
        #ifdef DEBUG_DUAL_SPLIT_Y
            if (vTexCoord.y < 0.5) pixel_out = texture(DEBUG_TEXTURE,vTexCoord).rgb;
        #endif

        #ifdef DEBUG_DUAL_SPLIT_Y_GAMMA
            if (vTexCoord.y < 0.5) pixel_out = pow(texture(DEBUG_TEXTURE,vTexCoord).rgb, vec3(1.08));
        #endif
            
        #ifdef DEBUG_DUAL_SPLIT_X
            if (vTexCoord.x > 0.5) pixel_out = texture(DEBUG_TEXTURE,vTexCoord).rgb;
        #endif
            
        #ifdef DEBUG_DUAL_SPLIT_MIRROR_X
            if (vTexCoord.x > 0.5) pixel_out = texture(DEBUG_TEXTURE,vec2(1-vTexCoord.x, vTexCoord.y) ).rgb;
        #endif

        #ifdef DEBUG_DUAL_SPLIT_MIRROR_X_GAMMA
            if (vTexCoord.x > 0.5) pixel_out = pow(texture(DEBUG_TEXTURE,vec2(1-vTexCoord.x, vTexCoord.y) ).rgb, vec3(1.11));
        #endif
            
        #ifdef DEBUG_PRINT_VALUE
            float maxdigits = 10.0;
            float decimalplaces = 2.0;
            float fvalue = vfprintvalue;
            vec2 vFragCoord = vec2( floor(vOutputCoord.x * params.OutputSize.x),
                                floor(vOutputCoord.y * params.OutputSize.y));
            pixel_out += PrintValueVec3( vTexCoord, vFragCoord, fvalue, maxdigits, decimalplaces );
        #endif
        
    #ifdef DEBUG_SHOW_CLIP
        float clip = max(max(pixel_out.r, pixel_out.g), pixel_out.b) ;
        if (clip  > 1.0)
            pixel_out = 1-pixel_out;//;-clip;
    #endif
            
    FragColor = vec4(pixel_out, 1.0);
    
    //FragColor = texture(halo_pass, vOutputCoord);
}
