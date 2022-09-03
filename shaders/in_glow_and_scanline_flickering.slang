#version 450

#include "config.inc"


#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;


void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;
   
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 3) uniform sampler2D FXAA_pass;
layout(set = 0, binding = 4) uniform sampler2D doublesize_pass;


// Blur sizes must not depend on input resolution
#define scalemod_x (params.SourceSize.x/360.0)
#define scalemod_y (params.SourceSize.y/270.0)

// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "pixel_glows.slang" 

#include "functions.include"


bool scanline_have_to_flicker(bool is_interlaced) {
    return ((scanline_flickering == 1.0) || ((scanline_flickering==2.0) && is_interlaced ));
}


bool flickering_scanline_needed(bool is_interlaced){
   if (DO_SCANLINES == 1.0) {
      if (scanline_flickering != 0.0) {
         if ( scanline_have_to_flicker(is_interlaced) ) {
            if  (! ( is_interlaced && (scanline_disable_on_interlace == 1.0))  ) {
               return true;
            }
         }
      }
   }
   return false;
}


vec3 get_scanline_mixed(vec3 pixel_in) {

   float in_luminance = ((pixel_in.r+pixel_in.g+pixel_in.b)/3) * DO_IN_GLOW;
   vec3 pixel_scanlined = pixel_in * SCANLINE_DARK;
   return mix(pixel_scanlined, pixel_in, in_luminance);
   return vec3(1.0);
}

vec3 flickering_scanline(vec3 pixel_in, bool is_interlaced, vec2 coords) {
   int scanline_period;
   int scanline_period_half;
   /* Puae switches from lowres to sdres on interlaced screens
      since we blindly double the h-resolution, because we need
      to double y resolution on low resolution to simulate scanlines
      and providing sd-res to fxaa, we can check if a screen is
      interlaced by testing v-resolution of source image.
      which could be at least 200*2(puae)*2(ourselves)=800px.
      Rest assured that everything over 576,
      (maximum pal overscanned) is interlaced.
   */
   if (is_interlaced) {
      scanline_period=4;
      scanline_period_half=2;
   } else {
      scanline_period=2;
      scanline_period_half=1;
   }

   float mymod = mod(coords.y * params.OutputSize.y , scanline_period);
   
   //Do flickering based on user prefs.
   //(blank odd lines on odd frames and even lines on even frames)
   if ((scanline_flickering == 1.0) || ((scanline_flickering==2.0) && is_interlaced )) {
         if  (int(mod(float(params.FrameCount),2  )) <  1.0 ) {
               if (mymod >= scanline_period_half) { return get_scanline_mixed(pixel_in) ; }
         } else {
               if (mymod < scanline_period_half) { return get_scanline_mixed(pixel_in) ; }
         }
   }
   return pixel_in;
}



void main()
{ 

//FIXME: flickering scanlines does not curve, and think they will never do due to moiree, not a big deal since they are barely visible.

   //Use to debug:
      //pixel_out=vec4(abs(sin(params.FrameCount/3.14/20))); //white fade
      //pixel_out=vec4(abs(sin(params.FrameCount/3.14/20)),0.0,0.0,0.0); //red fade
      //pixel_out=vec4(0.2);
   vec3 pixel_out;
   bool is_interlaced = (params.OriginalSize.y > MIN_LINES_INTERLACED) ? true : false ;
   bool exec_scanline_code = flickering_scanline_needed(is_interlaced);
   
   if (!exec_scanline_code && (DO_IN_GLOW == 0) ) return ;
   
   vec2 coords = vTexCoord;
   /*if (DO_CURVATURE == 1.0) {
      if ((GEOM_WARP_X > 0.0) || (GEOM_WARP_Y > 0.0))
            coords = Warp(vTexCoord,GEOM_WARP_X,GEOM_WARP_Y);
   }*/
   
   if (DO_IN_GLOW == 1.0) {
      if (DO_FXAA == 1.0)
         pixel_out = pixel_glow(FXAA_pass, in_glow_wh,in_glow_wh,in_glow_power,in_glow_gamma,coords, global.FXAA_passSize, global.FXAA_passSize).rgb;
            else
         pixel_out = pixel_glow(doublesize_pass, in_glow_wh,in_glow_wh,in_glow_power,in_glow_gamma,coords, global.FXAA_passSize, global.FXAA_passSize).rgb;
   } else {
      if (DO_FXAA == 1.0)
         pixel_out = texture(FXAA_pass, vTexCoord).rgb;
            else
         pixel_out = texture(doublesize_pass, coords).rgb;  
   }
      
   if (exec_scanline_code)
      pixel_out = flickering_scanline(pixel_out,is_interlaced, vTexCoord);

   FragColor = vec4((pixel_out),1.0);
}

