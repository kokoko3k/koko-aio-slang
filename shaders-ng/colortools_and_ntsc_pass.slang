#version 450

//#pragma format R32G32B32A32_SFLOAT

#define CWHITE  vec3(1.0)
#define CGRAY   vec3(0.5)
#define CBLACK  vec3(0.0)
#define CPURPLE vec3(1.0,0.0,1.0)
#define CRED    vec3(1.0,0.0,0.0)
#define CGREEN    vec3(0.0,1.0,0.0)
#define CBLUE    vec3(0.0,0.0,1.0)
#define CYELLOW  vec3(1.0,1.0,0.0)
#define CCUSTOM vec3(0.3,0.5,0.1)

#define DEBUG_COLOR vec3(1,1,1)
#define DEBUG_BLINK_TIME 50
#define DEBUG_GRADIENT_STEPS 255



//#define DEBUG
   //#define DEBUG_COLOR_CALIB
   //#define DEBUG_TIME_FADE
   //#define DEBUG_SOLID_COLOR
   //#define DEBUG_STEP_GRADIENT
   //#define DEBUG_STEP_GRADIENT_V
   //#define DEBUG_BLINK
   //#define DEBUG_BLINK_CIRCLE
   #define DEBUG_WALKING_CIRCLE
   //#define DEBUG_COLORWHEEL
   
   
#include "config.inc"

#ifndef D3D_WORKAROUND
   #define FPS_ESTIMATE_PASS halo_pre_gamma_passFeedback
#else
   #define FPS_ESTIMATE_PASS Original
#endif


#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec3 vTemperature_rgb;
layout(location = 3) out float vPixelgrid_intr_gamma_adj;
layout(location = 4) out vec3 vDebug;


#include "includes/functions.include.slang"



void main() {
   gl_Position = global.MVP * Position;
   //vTexCoord = TexCoord * 1.0001;
   //Since we are using linear filtering versus the previous (Original) pass, we whould not use *1.0001,
   //and we *need* linear filtering for deltarender purposes (see koko-aio-ng.slangp comments)
   //Or else the picture will be slightly blurred (visible only when output gamma is low).
   //Let's hope this will not break anything (classic diagonally broken screen).
   vTexCoord = TexCoord;
   
   vTemperature_rgb = vec3(1.0);
   if (TEMPERATURE != 6500)
      vTemperature_rgb = kelvin2rgb(TEMPERATURE);
   
   //interlaced scanline brightness compensation
      vPixelgrid_intr_gamma_adj = 1.0;
      if (pixelgrid_h_needed() && scanlines_will_alternate(is_interlaced()))
          vPixelgrid_intr_gamma_adj = PIXELGRID_INTR_GAMMA_ADJ;
   
   vDebug = vec3(0.0); //need to initialize to something.
   
   if (DO_TEST == 1.0) {
      vDebug = vec3(0.0);
   }
   else if (DO_TEST == 2.0) {
      vDebug = vec3(0.5);
   }
   else if (DO_TEST == 3.0) {
      vDebug = vec3(1.0);
   }   
   else if (DO_TEST == 4.0) {
      vDebug = vec3(vTexCoord.x);
   }   
   else if (DO_TEST == 5.0) {
      float cycle = mod(params.FrameCount / DEBUG_BLINK_TIME, 4);
           if (cycle <= 0) vDebug = vec3(vTexCoord.x);
      else if (cycle <= 1) vDebug = vec3(vTexCoord.x, 0.0, 0.0);
      else if (cycle <= 2) vDebug = vec3(0.0,vTexCoord.x,0.0);
      else if (cycle <= 3) vDebug = vec3(0.0,0.0,vTexCoord.x);
   }   
   else if (DO_TEST == 6.0) {
      float cycle = mod(params.FrameCount / DEBUG_BLINK_TIME, 4);
           if (cycle <= 0) vDebug = vec3(vTexCoord.y);
      else if (cycle <= 1) vDebug = vec3(vTexCoord.y, 0.0, 0.0);
      else if (cycle <= 2) vDebug = vec3(0.0,vTexCoord.y,0.0);
      else if (cycle <= 3) vDebug = vec3(0.0,0.0,vTexCoord.y);
   }   
   else if (DO_TEST == 7.0) {
      float cycle = mod(params.FrameCount / DEBUG_BLINK_TIME, 6);
           if (cycle <= 0) vDebug = vec3(vTexCoord.x, vTexCoord.y, 0.0);
      else if (cycle <= 1) vDebug = vec3(vTexCoord.x, 0.0,         vTexCoord.y);
      else if (cycle <= 2) vDebug = vec3(vTexCoord.y, vTexCoord.x, 0.0);
      else if (cycle <= 3) vDebug = vec3(vTexCoord.y, 0.0,         vTexCoord.x);
      else if (cycle <= 4) vDebug = vec3(0.0,         vTexCoord.x, vTexCoord.y);
      else if (cycle <= 5) vDebug = vec3(0.0,         vTexCoord.y, vTexCoord.x);
   }   
   else if (DO_TEST == 8.0) {
      if (mod(params.FrameCount, DEBUG_BLINK_TIME*2) < DEBUG_BLINK_TIME) 
         vDebug = vec3(0.0) ;
      else 
         vDebug = vec3(1.0) ;
   }
   else if (DO_TEST == 9.0) {
      float time_fade = abs(sin(params.FrameCount/3.14/20));
      vec3 color_fade = vec3(1.0) * time_fade;
      vDebug = color_fade;
   }      
   else if (DO_TEST == 10.0) {
      float time_fade = abs(sin(params.FrameCount/3.14/20));
      vec3 color_fade = vec3(1.0,0.0,0.0) * time_fade;
      vDebug = color_fade;
   }      
   else if (DO_TEST == 11.0) {
      float time_fade = abs(sin(params.FrameCount/3.14/20));
      vec3 color_fade = vec3(0.0, 1.0, 0.0) * time_fade;
      vDebug = color_fade;
   }      
   else if (DO_TEST == 12.0) {
      float time_fade = abs(sin(params.FrameCount/3.14/20));
      vec3 color_fade = vec3(0.0, 0.0, 1.0) * time_fade;
      vDebug = color_fade;
   }      
   
}


#pragma stage fragment

#include "includes/functions.include.slang"

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec3 vTemperature_rgb;
layout(location = 3) in float vPixelgrid_intr_gamma_adj;
layout(location = 4) in vec3 vDebug;

layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 2) uniform sampler2D Source;
layout(set = 0, binding = 3) uniform sampler2D colortools_and_ntsc_passFeedback;
layout(set = 0, binding = 5) uniform sampler2D FPS_ESTIMATE_PASS;

vec3 colorwheel(vec2 uv){
   float timeoffset = params.FrameCount / 120.0;
   vec2 uvc = -1.0 * ((2.0 * uv) - 1.0);
   float dist = length(uvc);
   float ang = (atan(uvc.y, uvc.x) + pi) / (2.0 * pi) - timeoffset;
   ang = mod(ang, 1.0);
   vec3 colHSV = vec3(ang, 1.0, dist);
   return hsv2rgb(colHSV);
}


vec3 gradient(vec3 start, vec3 end, float m, float q){
   m = ceil(m*q)/q;
   return mix(start, end, m);
}

vec3 debug() {
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

   #elif defined DEBUG_STEP_GRADIENT_V
      pixel_debug = DEBUG_COLOR * floor(vTexCoord.y* DEBUG_GRADIENT_STEPS )/ DEBUG_GRADIENT_STEPS ;
      
   #elif defined DEBUG_BLINK
      if (mod(params.FrameCount, DEBUG_BLINK_TIME*2) < DEBUG_BLINK_TIME) 
         pixel_debug = vec3(0.0) ;
      else 
         pixel_debug = DEBUG_COLOR;
   
   #elif defined DEBUG_BLINK_CIRCLE
      vec2 center = vTexCoord - vec2(0.5,0.5);
      float radius = 0.2;
      pixel_debug = vec3(1 - step(radius, length(center)));
      pixel_debug *= float( ( mod(params.FrameCount, DEBUG_BLINK_TIME * 2) < DEBUG_BLINK_TIME));
      pixel_debug *= DEBUG_COLOR;
      
   #elif defined DEBUG_WALKING_CIRCLE
      float speed = 4.0;
      vec2 center = vec2(  mod(params.FrameCount*speed, params.SourceSize.x*1.2)/params.SourceSize.x  -0.1      , 0.5);
      center = vTexCoord - center;
      float radius = 0.05;
      pixel_debug = vec3(1 - step(radius, length(center)));
      pixel_debug *= DEBUG_COLOR;
      
   #elif defined DEBUG_COLORWHEEL   
      pixel_debug = colorwheel(vTexCoord);   
   
   #elif defined DEBUG_COLOR_CALIB
      pixel_debug = vec3(0.0);
      if (vTexCoord.y < 0.1)
         pixel_debug = gradient(CBLACK, CBLUE, vTexCoord.x, DEBUG_GRADIENT_STEPS);
      else if (vTexCoord.y < 0.2)
         pixel_debug = gradient(CBLACK, CGREEN, vTexCoord.x, DEBUG_GRADIENT_STEPS);
      else if (vTexCoord.y < 0.3)
         pixel_debug = gradient(CBLACK, vec3(0.0,1.0,1.0), vTexCoord.x, DEBUG_GRADIENT_STEPS);
      else if (vTexCoord.y < 0.4)
         pixel_debug = gradient(CBLACK, CRED, vTexCoord.x, DEBUG_GRADIENT_STEPS);
      else if (vTexCoord.y < 0.5)
         pixel_debug = gradient(CBLACK, CPURPLE, vTexCoord.x, DEBUG_GRADIENT_STEPS); 
      else if (vTexCoord.y < 0.6)
         pixel_debug = gradient(CBLACK, CYELLOW, vTexCoord.x, DEBUG_GRADIENT_STEPS); 
      else if (vTexCoord.y < 0.7)
         pixel_debug = gradient(CBLACK, CWHITE, vTexCoord.x, DEBUG_GRADIENT_STEPS); 
      else if (vTexCoord.y < 0.8)
         pixel_debug = gradient(vec3(0.9), vec3(1.0), vTexCoord.x, 8); 
      else if (vTexCoord.y < 0.9)
         pixel_debug = gradient(vec3(0.0), vec3(0.1), vTexCoord.x, 8);    
   #endif
   
   return pixel_debug;
}


bool first_in_range_strict(float a, float lo, float hi) {
   // return a inside ]lo...hi[ (lo and hi not included in range)
   float bounded = clamp(a, lo+eps, hi-eps);
   return a == bounded;
}

vec3 persistence(vec3 feedback, vec3 pixel_now, float start_decay, float late_persistence, float motion_blur_cancel) {
   //start_decay: is the initial decay, the fast one: 1.0 means instantaneous, try around 0.8
   //end decay the higher, the more the persistance in the long run, try around 1.0;
   //motion_blur_cancel: 0.0 means full blur on bright areas; try around 2.5

   vec3 diff=(feedback - pixel_now);

   vec3 speed_fast = diff * start_decay;
   vec3 speed_slow = diff / (late_persistence+eps); //fma() not usable pr slower. 
      
   vec3 fade_speed = mix(speed_slow, speed_fast, diff );
   
   //higher speed is needed when composing over brighter colors to avoid motion blur
   fade_speed = fade_speed + (pixel_now*motion_blur_cancel);
   //fade_speed = fma(pixel_now, vec3(motion_blur_cancel), vec3(fade_speed)); //ASM PROOF: SLOWER
   
   //Ensure a minimum speed to reach 0.0 and clamp to 1.0 to avoid funky effects
   float min_speed = 0.05  ;
   fade_speed=clamp(fade_speed, min_speed, 1.0);
   

   //Compute the persistent light by mixing pixel current and previous one
   vec3 pixel_persistent = mix(feedback, pixel_now, fade_speed );  
   
   //blend only if we are fading out
      vec3 light_fading_out = vec3(greaterThan(feedback, pixel_now));
      return mix(pixel_now, pixel_persistent, light_fading_out);
   }
   


void main() {
   vec2 co = vTexCoord;
   
   vec3 pixel_in = texture(Source, co).rgb;
   
   //eventually return black pixel
   #define _TOL 0.001
   #define RECT01 vec4( vec2(0.0-_TOL), vec2(1.0+_TOL) )
   if (is_first_outside_rect(co, RECT01))
      pixel_in = vec3(0.0);
   
   vec3 pixel_out = pixel_in;

   pixel_out.rgb = mix(pixel_out, vDebug, min(DO_TEST, 1.0)  );
   
   #ifdef DEBUG
      //Cant "debug" ntsc artifacts because it samples from source (original)
      pixel_out = debug();
   #endif
      
   if (DO_CCORRECTION == 1.0) {
      pixel_out = color_tools(pixel_out, vTemperature_rgb);
	}

   if (DO_PPERSISTENCE == 1.0) {
      if (params.OutputSize.xy == global.colortools_and_ntsc_passFeedbackSize.xy) {
         vec3 feedback = texture(colortools_and_ntsc_passFeedback, co).rgb;
         float motion_blur_cancel = 2.5;
         pixel_out = persistence(feedback, pixel_out, PPERSISTENCE_START, PPERSISTENCE_END, motion_blur_cancel);
      }
   }
 
   //Clamp RGB to 0..1000.0
   pixel_out = max(pixel_out, vec3(0.0));
   
   pixel_out.rgb = pow(pixel_out.rgb, vec3(vPixelgrid_intr_gamma_adj));
   

   // Past field interlace emulation:
   if (is_interlaced()) {
      if ( !low_fps(FPS_ESTIMATE_PASS) ) {
         
         bool even_line = line_is_even(vTexCoord.y, params.OriginalSize.y);
         vec3 past =  texture(colortools_and_ntsc_passFeedback, vTexCoord).rgb;
         vec3 mymix = mix(pixel_out.rgb, past, PIXELGRID_INTR_PAST_FIELD);
         
         if (frame_is_even()) {
            if (!even_line)
               pixel_out.rgb = mymix;
         } else {
            if (even_line)
               pixel_out.rgb = mymix;
         }
      }
   }

   
   FragColor.rgb = pixel_out;
}


