#version 450

#include "config.inc"


#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;


void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D FXAA_pass;



void main()
{ 

   int scanline_period;
   int scanline_period_half;
   int is_interlaced;
   /* Puae switches from lowres to sdres on interlaced screens
      since we blindly double the h-resolution, because we need
      to double y resolution on low resolution to simulate scanlines
      and providing sd-res to fxaa, we can check if a screen is
      interlaced by testing v-resolution of source image.
      which could be at least 200*2(puae)*2(ourselves)=800px.
      Rest assured that everything over 576,
      (maximum pal overscanned) is interlaced.
   */
   if (params.SourceSize.y > 580) {
      scanline_period=4;
      scanline_period_half=2;
      is_interlaced=1;
   } else {
      scanline_period=2;
      scanline_period_half=1;
      is_interlaced=0;
   }

   vec4 pixel = vec4(texture(FXAA_pass, vTexCoord).xyz,1.0);
   if ( SCANLINE_DARK < 1.0 ) {
      float mymod = mod(vTexCoord.y * params.OutputSize.y , scanline_period);
      
      //No flickering (dumbly blank even lines)
      if ((scanline_flickering == 0.0) ||
         ((scanline_flickering==2.0) && (is_interlaced == 0))) {
               if (mymod > scanline_period_half) { pixel *= SCANLINE_DARK ;}
      } else {
         //Do flickering based on user prefs.
         //(blank odd lines on odd frames and even lines on even frames)
         if ((scanline_flickering == 1.0) ||
            ((scanline_flickering==2.0) && (is_interlaced == 1))) {
               if  (int(mod(float(params.FrameCount),2  )) <  1.0 ) {
                     if (mymod >= scanline_period_half) { pixel *= SCANLINE_DARK; }
               } else {
                     if (mymod < scanline_period_half) { pixel *= SCANLINE_DARK; }
               }
         }
      }
   }


/*   float mymod = mod(vTexCoord.y * params.OutputSize.y , scanline_period);
   

   if  (int(mod(float(params.FrameCount),20.0  )) <  10.0 ) {
      if (mymod >= 2.0) { pixel *= SCANLINE_DARK; }
   } else {
      if (mymod <= 2.0) { pixel *= SCANLINE_DARK; } 
   }
   
*/
   FragColor = pixel;
}





/*void main()
{
   vec4 pixel = vec4(texture(FXAA_pass, vTexCoord).xyz,1.0);
        if ( SCANLINE_DARK < 1.0 ) {
            float mymod = mod(vTexCoord.y * params.OutputSize.y , 2.0);
            if  (int(mod(float(params.FrameCount),2.0  )) == 1) {
                  if (mymod < 1.0) { pixel *= SCANLINE_DARK; }
            } else {
                  if (mymod >= 1.0) { pixel *= SCANLINE_DARK; }
            }
        }
   FragColor = pixel;
}*/


