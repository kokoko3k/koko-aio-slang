#version 450

#include "config.inc"
#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out float vDynamicSeed;
layout(location = 2) out float vFlickering_power;
layout(location = 3) out float vDo_flickering;
layout(location = 4) out vec2  vFlickerCoords;

#include "includes/functions.include.slang"


void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   
   //Generate a seed that changes over time for temporal random noise
      vDynamicSeed = mod(params.FrameCount, 120.0001);
      
   vDo_flickering  = float ( scanline_have_to_flicker(is_interlaced()) ) ; 
   
   if (vDo_flickering == 1.0) {
      //Flicker one over 3 frames:
         float ModFlicker = params.FrameCount % 3;
      
      //Compute y flicker offset:
         float FlickerOffset = 0.0;
         float line_tick = (params.OriginalSize.y > MIN_LINES_INTERLACED ) ? 1 : 2 ;
         if (ModFlicker == 1.0 )
            FlickerOffset = params.OriginalSize.w/line_tick;
         else if (ModFlicker == 2.0)
            FlickerOffset = -params.OriginalSize.w/line_tick;
      
      //Export flicker coords for Fragment shader here:
         vFlickerCoords =  vec2(TexCoord.x, TexCoord.y + FlickerOffset);
         
      vFlickering_power = DO_PIXELGRID * PIXELGRID_INTR_FLICK_POWR;
   }

}


#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float vDynamicSeed;
layout(location = 2) in float vFlickering_power;
layout(location = 3) in float vDo_flickering;
layout(location = 4) in vec2  vFlickerCoords;

layout(location = 0) out vec4 FragColor;  

layout(set = 0, binding = 2) uniform sampler2D Source;

#include "includes/functions.include.slang"

vec3 pixel_flickering() {
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

   
   vec3 pixel_cur = texture(Source,vTexCoord).rgb;   
   vec3 flickline = texture(Source,vFlickerCoords).rgb;
   
   float lumdiff = abs(flickline.r + flickline.g + flickline.b - pixel_cur.r - pixel_cur.g - pixel_cur.b);

   lumdiff = min(lumdiff * vFlickering_power, 1.0);
   return mix(pixel_cur,flickline,lumdiff);
}


void main() {
   

   /* since flickering code needs
      luminosity difference between 2 vertical lines
      both have to be processed through color corrections and rgb pixel offsets.
      before flickering code can operate. (pixel_no_flicker)
      Therefore we call pixel_no_flicker inside it when we want flickering scanlines
      and outside id when we dont.
   */

   vec3 pixel_out;
   if (DO_PIXELGRID == 0.0)
      pixel_out = texture(Source, vTexCoord).rgb;
   
   else if (vDo_flickering==1.0) 
      pixel_out = pixel_flickering();
   else
   //Implicit else: DO_SCANLINES == 1.0 but no flickering needed.
   pixel_out = texture(Source, vTexCoord).rgb;

   
   if (DO_RF_NOISE > 0.0) {
      vec3 noise = vec3(random_fast(RF_NOISE_STRENGTH, vTexCoord * vDynamicSeed));
      pixel_out += noise;
   }
   
   //Here lies the blur modifier from ntsc pass to glow.
   //I'm not expecting any performance hit, since the lookup should have been cached alreadyl
      float pixel_alpha = texture(Source, vTexCoord).a;
   
   
   //dots, need in_coords = in_coords - global.flick_and_noise_passSize.zw*0.5 in pixelgrid pass
   //vec2 integerCoords = floor(vTexCoord.xy * params.OutputSize.xy);
   //float black = float(  mod(integerCoords.x, 2.0) != 0.0 && mod(integerCoords.y, 2.0) != 0.0 );
   //float black = float(  mod(integerCoords.y, 2.0) != 0.0 );
   //FragColor = vec4(pixel_out*black, pixel_alpha);
   
   
   FragColor = vec4(pixel_out, pixel_alpha);

}


