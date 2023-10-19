#version 450


#define CWHITE  vec3(1.0)
#define CGRAY   vec3(0.5)
#define CBLACK  vec3(0.0)
#define CPURPLE vec3(1.0,0.0,1.0)
#define CRED    vec3(1.0,0.0,0.0)
#define CGREEN    vec3(0.0,1.0,0.0)
#define CBLUE    vec3(0.0,0.0,1.0)
#define CYELLOW  vec3(1.0,1.0,0.0)
#define CCUSTOM vec3(0.3,0.5,0.1)

#define DEBUG_COLOR vec3(1.0)
#define DEBUG_BLINK_TIME 30
#define DEBUG_GRADIENT_STEPS 64



//#define DEBUG
   //#define DEBUG_COLOR_CALIB
   #define DEBUG_TIME_FADE
   //#define DEBUG_SOLID_COLOR
   //#define DEBUG_STEP_GRADIENT
   //#define DEBUG_STEP_GRADIENT_V
   //#define DEBUG_BLINK
   //#define DEBUG_BLINK_CIRCLE
   //#define DEBUG_COLORWHEEL
   
   
#include "config.inc"

#define NTSC_FILTER_WIDTH_MAX 25
#define NTSC_FILTER_MIDDLE NTSC_FILTER_WIDTH/2

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 1) out vec3 vTemperature_rgb;
layout(location = 0) out vec2 vTexCoord;
layout(location = 2) out float vNTSC_FILTER_FC;
layout(location = 3) out float vNTSC_FILTER_SCF;
layout(location = 4) out float vNTSC_weights[NTSC_FILTER_WIDTH_MAX];


#include "includes/functions.include.slang"


/* hann() sinc() functions by xot:
 * copyright (c) 2017-2018, John Leffingwell
 * license CC BY-SA Attribution-ShareAlike
 * ntscdec() function, same license and attribution,
 * slightly modified by me.
 * https://www.shadertoy.com/view/Mdffz7
 */

float hann(float n, float N) {
    return 0.5 * (1.0 - cos((TAU*n)/(N-1.0))) ;
}

float sinc(float x) {
   //if (x == 0.0) return 1.0;
   x = x + eps;
   return sin(pi*x) / (pi*x); 
   //FIXME maybe faster (parallelism) with:
   //return sin( pi*(x+eps) / (pi*(x+eps) ) );
}


void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord * 1.0001;

   if (DO_NTSC_ARTIFACTS > 0.0) {
      vNTSC_FILTER_FC = NTSC_FILTER_FC * 0.1;
      vNTSC_FILTER_SCF = NTSC_FILTER_SCF * 0.1;
      float sum = 0.0;
      int N = int(NTSC_FILTER_WIDTH);
      //  Compute sampling weights
      for (int n = 0; n < N; n++) {
         vNTSC_weights[n] = hann(float(n), float(N)) * sinc(vNTSC_FILTER_FC * float(n-NTSC_FILTER_MIDDLE));
         sum += vNTSC_weights[n];
      }
      //  Normalize sampling weights
      for (int n = 0; n < N; n++) {
         vNTSC_weights[n] /= sum;
      }
   }
   if (TEMPERATURE != 6500)
      vTemperature_rgb = kelvin2rgb(TEMPERATURE);
}


#pragma stage fragment

#include "includes/functions.include.slang"

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec3 vTemperature_rgb;
layout(location = 2) in float vNTSC_FILTER_FC;
layout(location = 3) in float vNTSC_FILTER_SCF;
layout(location = 4) in float vNTSC_weights[NTSC_FILTER_WIDTH_MAX];


layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 2) uniform sampler2D Source;
layout(set = 0, binding = 3) uniform sampler2D colortools_and_ntsc_passFeedback;


vec3 colorwheel(vec2 uv){
   float timeoffset = params.FrameCount / 120.0;
   vec2 uvc = -1.0 * ((2.0 * uv) - 1.0);
   float dist = length(uvc);
   float ang = (atan(uvc.y, uvc.x) + pi) / (2.0 * pi) - timeoffset;
   ang = mod(ang, 1.0);
   vec3 colHSV = vec3(ang, 1.0, dist);
   return hsv2rgb(colHSV);
}

//	Colorspace conversion matrix for YIQ-to-RGB
const mat3 YIQ2RGB = mat3(1.000, 1.000, 1.000,
                          0.956,-0.272,-1.106,
                          0.621,-0.647, 1.703);

const mat3 RGB2YIQ = mat3(
         0.2989, 0.5959, 0.2115,
         0.5870, -0.2744, -0.5229,
         0.1140, -0.3216, 0.3114);


#define pi10 pi*10
#define PHASE_SHIFT_FOR_BLUR_K pi/3
vec4 ntscdec(vec2 uv) {
   vec2 size = params.SourceSize.xy;
   //	Sample composite signal and decode to YIQ
      vec3 YIQ_processed = vec3(0.0);
      vec3 YIQ_processed_shifted = vec3(0.0);
      //by doing another ntsc filtering with this histed phase, we're able to better identify
      //artifacts that will drive the blur modulation.
         float phase_shift_for_blur;
         
      int N = int(NTSC_FILTER_WIDTH);
      for (int n=0; n < N; n++) {
         vec2 pos = uv + vec2(float(n-NTSC_FILTER_MIDDLE) / size.x, 0.0);
         float phase =  TAU * (vNTSC_FILTER_SCF * size.x * pos.x);
         float phase_shift_for_blur = phase  + PHASE_SHIFT_FOR_BLUR_K;
         
         phase += ( pos.y * -pi10 ) * (NTSC_PHASE_SHIFT);
         
         //float phase =  TAU * (vNTSC_FILTER_SCF * size.x * pos.x) + ( pos.y * -pi10 * NTSC_PHASE_SHIFT)
         // ( pos.y * - 31.4);
         //Just sample luminance via yiq:
            vec3 smp = vec3((texture(Source, pos).rgb * RGB2YIQ).x);
            YIQ_processed += vec3(1.0, cos(phase), sin(phase)) * smp * vNTSC_weights[n];
            YIQ_processed_shifted += vec3(1.0, cos(phase_shift_for_blur), sin(phase_shift_for_blur)) * smp * vNTSC_weights[n];
      }

   vec3 RGB_ori = texture(Source, uv).rgb;
   vec3 YIQ_ori = RGB_ori * RGB2YIQ;

   vec3 YIQ_result = vec3(YIQ_ori.x, YIQ_ori.yz + YIQ_processed.yz * NTSC_MIX);
   
   float artifacts_mask = abs(YIQ_processed.y)         + abs(YIQ_processed.z) + 
                          abs(YIQ_processed_shifted.y) + abs(YIQ_processed_shifted.z);
   
                          
   //artifacts_mask = pow(artifacts_mask, 0.25);
                          
   return vec4(YIQ_result * YIQ2RGB, artifacts_mask);
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

void main() {
   
   //This will go into alpha channel to make glow aware of it and blur more.
   //It could be configurable.
   vec3 pixel_out;
   float artifact_mask = 0.0;

   
   if (DO_NTSC_ARTIFACTS > 0.5) {
      //Get ntsc picture
         vec4 ntsc_decoded = ntscdec(vTexCoord);
      //apply the minimum treshold to artifact mask
         artifact_mask = smoothstep(NTSC_ARTF_TRSH, 1.0, ntsc_decoded.a)*1.0;

      //Optionally completely cut-off artifacts under treshold:
         vec3 pixel_clean = texture(Source, vTexCoord).rgb;
         ntsc_decoded = mix(ntsc_decoded, vec4(pixel_clean, 0.0) , (1-artifact_mask)*NTSC_ARTF_ZAP );
         //Update the artifact mask if something has been cancelled
            artifact_mask = min(artifact_mask, ntsc_decoded.a);

            //artifact_mask = clamp (artifact_mask*1.0, 0.0,1.0);
            artifact_mask *= 2.0;
            
            
      pixel_out = ntsc_decoded.rgb;
      
   } else {
      
      pixel_out = texture(Source, vTexCoord).rgb;
   }

  
   
   #ifdef DEBUG
      //Vant "debug" ntsc artifacts because it samples from source (original)
      pixel_out = debug();
   #endif
      
  FragColor = vec4(pixel_out, 1.0);
   
   if (DO_CCORRECTION == 1.0)
      pixel_out = color_tools(pixel_out, vTemperature_rgb);

   if (DO_DOT_MATRIX + DOT_M_MBLUR_STR > 1.0) {
      vec3 feedback = texture(colortools_and_ntsc_passFeedback, vTexCoord).rgb;
      
      vec3 m_blur_adapted = vec3(DOT_M_MBLUR_STR);
      if (DOT_M_MBLUR_MODE > 0.0) {
         vec3 adaption = mix_step (pixel_out - feedback,
                                   feedback - pixel_out,
                                   DOT_M_MBLUR_MODE -1);
         //adaption = mix_step(adaption, -adaption, DOT_M_MBLUR_MODE -1);
         m_blur_adapted *= clamp( adaption, 0.0, 1.0 );
         m_blur_adapted = pow(m_blur_adapted, vec3(0.25));
      }
      pixel_out = mix(pixel_out, feedback,          m_blur_adapted  );
   }
   
   
   FragColor = vec4(pixel_out, artifact_mask);
   //FragColor = vec4(artifacts);
}


