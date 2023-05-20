#version 450

#define CWHITE  vec3(1.0)
#define CGRAY   vec3(0.5)
#define CBLACK  vec3(0.0)
#define CPURPLE vec3(1.0,0.0,1.0)
#define CRED    vec3(1.0,0.0,0.0)
#define CCUSTOM vec3(1.0,0.5,0.1)

#define DEBUG_COLOR CWHITE
#define DEBUG_BLINK_TIME 20
#define DEBUG_GRADIENT_STEPS 128

//#define DEBUG
   //#define DEBUG_TIME_FADE
   #define DEBUG_SOLID_COLOR
   //#define DEBUG_GRADIENT
   //#define DEBUG_STEP_GRADIENT
   //#define DEBUG_BLINK
   //#define DEBUG_BLINK_CIRCLE
   //#define DEBUG_COLORWHEEL
   

#include "config.inc"
#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out float vDynamicSeed;
layout(location = 2) out float vFlickering_power;
layout(location = 3) out float vDo_flickering;

#include "includes/functions.include.slang"


void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   
   //Generate a seed that changes over time for temporal random noise
      vDynamicSeed = mod(params.FrameCount, 120.0001);
      
   vFlickering_power = DO_PIXELGRID * PIXELGRID_INTR_FLICK_POWR;
   
   vDo_flickering  = float ( scanline_have_to_flicker(is_interlaced()) ) ; 
}


#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float vDynamicSeed;
layout(location = 2) in float vFlickering_power;
layout(location = 3) in float vDo_flickering;

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
   float mymod = params.FrameCount % 3;

   if (mymod == 0.0) return pixel_cur;
   float line_tick = (params.OriginalSize.y > MIN_LINES_INTERLACED ) ? 1 : 2 ;
   vec3 flickline;
   if (mymod == 1.0 )
      flickline = texture(Source, vTexCoord + vec2(0.0,params.OriginalSize.w/line_tick)).rgb;
   else if (mymod == 2.0)
      flickline = texture(Source, vTexCoord - vec2(0.0,params.OriginalSize.w/line_tick)).rgb;

   float lumdiff = abs(flickline.r + flickline.g + flickline.b - pixel_cur.r - pixel_cur.g - pixel_cur.b);

   lumdiff = min(lumdiff * vFlickering_power, 1.0);
   return mix(pixel_cur,flickline,lumdiff);
   

}


vec3 colorwheel(vec2 uv){
   float timeoffset = params.FrameCount / 120.0;
   vec2 uvc = -1.0 * ((2.0 * uv) - 1.0);
   float dist = length(uvc);
   float ang = (atan(uvc.y, uvc.x) + pi) / (2.0 * pi) - timeoffset;
   ang = mod(ang, 1.0);
   vec3 colHSV = vec3(ang, 1.0, dist);
   return hsv2rgb(colHSV);
}

void debug() {
//Just test patterns here
   vec3 pixel_debug;
   
   #ifdef DEBUG_TIME_FADE
      float time_fade = abs(sin(params.FrameCount/3.14/20));
      vec3 color_fade = DEBUG_COLOR * time_fade;
      pixel_debug = color_fade;
      
   #elif defined DEBUG_SOLID_COLOR   
      pixel_debug = DEBUG_COLOR;
      
   #elif defined DEBUG_GRADIENT
      pixel_debug = DEBUG_COLOR * vTexCoord.x;
      
   #elif defined DEBUG_STEP_GRADIENT
      pixel_debug = DEBUG_COLOR * floor(vTexCoord.x* DEBUG_GRADIENT_STEPS )/ DEBUG_GRADIENT_STEPS ;
      
   #elif defined DEBUG_BLINK
      if (mod(params.FrameCount, DEBUG_BLINK_TIME*2) < DEBUG_BLINK_TIME) 
         pixel_debug = vec3(0.2) ;
      else 
         pixel_debug = DEBUG_COLOR;
   
   #elif defined DEBUG_BLINK_CIRCLE
      vec2 center = vTexCoord - vec2(0.5,0.5);
      float radius = 0.1;
      pixel_debug = vec3(1 - step(radius, length(center)));
      pixel_debug *= float( ( mod(params.FrameCount, DEBUG_BLINK_TIME * 2) < DEBUG_BLINK_TIME));
      pixel_debug *= DEBUG_COLOR;
      
   #elif defined DEBUG_COLORWHEEL   
      pixel_debug = colorwheel(vTexCoord);   
   #endif
   
   FragColor = vec4(pixel_debug,1.0);
}


void main() {
   
   #ifdef DEBUG
      debug(); return;
   #endif

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
   
   FragColor = vec4(pixel_out, pixel_alpha);
}


