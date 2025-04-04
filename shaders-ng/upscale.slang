#version 450

#include "config.inc"
#include "includes/functions.include.slang"

#ifndef D3D_WORKAROUND
   #define FPS_ESTIMATE_PASS halo_pre_gamma_passFeedback
#else
   #define FPS_ESTIMATE_PASS Original
#endif


#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

layout(location = 3) out float vDynamicSeed;

layout(location = 12) out float vDo_flickering;
layout(location = 13) out vec2  vFlickerCoords;

void main() {

   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   
   //noise
   vDynamicSeed = mod(params.FrameCount, 120.0001);
   
   //flickering helper
   vDo_flickering  = float ( scanline_have_to_flicker(is_interlaced()) ) ; 
   #ifdef FLICKER_IN_MOTION
      vDo_flickering = 1.0;
   #endif
   if (vDo_flickering == 1.0) {
      //Flicker one over 3 frames:
         float ModFlicker = params.FrameCount % 3;
      
      //Compute y flicker offset:
         float FlickerOffset = 0.0;
         float line_tick = is_interlaced() ? 1 : 2 ;
         if (ModFlicker == 1.0 )
            FlickerOffset = params.OriginalSize.w/line_tick;
         else if (ModFlicker == 2.0)
            FlickerOffset = -params.OriginalSize.w/line_tick;
      //Export flicker coords for Fragment shader here:
         vFlickerCoords =  vec2(TexCoord.x, TexCoord.y + FlickerOffset);
   }

}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;

layout(location = 3) in float vDynamicSeed;

layout(location = 12) in float vDo_flickering;
layout(location = 13) in vec2  vFlickerCoords;

layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 4) uniform sampler2D colortools_and_ntsc_pass;
layout(set = 0, binding = 5) uniform sampler2D colortools_and_ntsc_passFeedback;
layout(set = 0, binding = 6) uniform sampler2D FPS_ESTIMATE_PASS;

vec4 texture_ovr_nearest( sampler2D tex, vec2 co) {
   //return texture(tex, co);
   vec4 c = texture_NEAREST(tex, co, params.SourceSize);
   #ifdef _KOKO_AA_PRELINEARIZE
      c.rgb = pow(c.rgb, vec3(_KOKO_AA_PRELINEARIZE_IN));
   #endif
   return c;
}


vec4 textureLod_ovr(sampler2D tex, vec2 co, float lod) {
   vec4 c = textureLod(tex, co, lod);
   #ifdef _KOKO_AA_PRELINEARIZE
      c.rgb = pow(c.rgb, vec3(_KOKO_AA_PRELINEARIZE_IN));
   #endif
   return c;
}

vec4 texture_ovr_nearest_lod0( sampler2D tex, vec2 co) {
   //return texture(tex, co);
   vec4 c = texture_NEAREST_lod(tex, co, params.SourceSize, 0.0);
   #ifdef _KOKO_AA_PRELINEARIZE
      c.rgb=pow(c.rgb, vec3(_KOKO_AA_PRELINEARIZE_IN));
   #endif
   return c;
}


vec3 pixel_flickering(vec3 pixel_cur) {
/* Simulates the flickering effect of the interlaced screens.
 * As I remember, it was visible when a line and the next had high
 * luminosity differences.
 * So we need to sample the current line and the previous one
 * (eventually applying color corrections to both).
 *
 * Repeating the following:
 * On frame 0, return the "clean" pixel
 * On frame 1, mix the upper pixel with the current one
 * On frame 2, mix the lower pixel with the current one
 *
 * The effect of the mix is the flickering itself, and we modulate
 * the mix according to the luminance difference between the current
 * pixel and the mixed one.
 *
 * We choose to alternate on a period of 3,
 * (thus considering the upper pixel and the lower one)
 * or else the high pixel persistance of lcd displays wont allow
 * to see the effect (the lcd panel would just mix the pixels by itself (meh).
 */

   vec3 flickline = texture(colortools_and_ntsc_pass,vFlickerCoords).rgb;
   
   //float lumdiff = abs( flickline.r + flickline.g + flickline.b - pixel_cur.r - pixel_cur.g - pixel_cur.b);
   //float lumdiff = abs( (flickline.r + flickline.g) + (flickline.b - pixel_cur.r) - (pixel_cur.g + pixel_cur.b) ); //1687 1754 2946   ASM PROOF: FASTER
   float lumdiff = abs( dot(flickline.rgb, vec3(1.0)) - dot(pixel_cur.rgb, vec3(1.0)));// 1685 1750 2948 //ASM PROOF: Faster on SIMD8 and SIMD16, slower on SIMD32

   
   // disable flickering on 25 and 30fps content:
   if (low_fps(FPS_ESTIMATE_PASS)) lumdiff = 0.0;
   
   lumdiff = min(lumdiff * PIXELGRID_INTR_FLICK_POWR, 1.0);
   

   #ifdef FLICKER_IN_MOTION
      lumdiff = 0.4;
      vec3 prev_frame = texture(colortools_and_ntsc_passFeedback, vTexCoord).rgb;
      vec3 cur_frame = texture(colortools_and_ntsc_pass, vTexCoord).rgb;
      float is_moving = float(prev_frame != cur_frame);
      lumdiff *= is_moving;
   #endif
   
   return mix(pixel_cur.rgb,flickline.rgb,lumdiff);

}

void main() {
   
   #ifndef D3D_WORKAROUND
      if (fps_halver_is_skipped_frame())
         return;
   #endif
   
   vec4 pixel_out;
   pixel_out.rgb = texture_NEAREST(colortools_and_ntsc_pass, vTexCoord, params.SourceSize).rgb;
   
   pixel_out.a = texture(colortools_and_ntsc_pass, vTexCoord).a;//, params.SourceSize).a;
   
   // If we need to smooth waterfalls, it is good to smooth
   // their detection mask too, maybe using an higher lod ist good tho,
   // but we still require linear sampling.
   pixel_out.a = 0.0;



   
   if (vDo_flickering==1.0) 
      pixel_out.rgb = pixel_flickering(pixel_out.rgb).rgb;
   
      
   if (DO_RF_NOISE > 0.01 ) {
      //Unfortunately we need to clamp to min 0.0 again after applying noise
      //to avoid glitches on amd (and probably nvidia too).
      //It should be possible to change the noise function to just emit positive
      //numbers and pre-lowering the brightness of pixel_out in the very first pass tho.

         float rfnoise = get_rf_noise(vTexCoord * vDynamicSeed);
         pixel_out.rgb += rfnoise;
         pixel_out.rgb = max(pixel_out.rgb, vec3(0.0));
         
   }

   FragColor.rgb = pixel_out.rgb;
   
}
