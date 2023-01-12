#version 450
#include "config.inc"

#define NTSC_FILTER_WIDTH_MAX 25
#define NTSC_FILTER_MIDDLE NTSC_FILTER_WIDTH/2

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
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


//	Hann windowing function
float hann(float n, float N) {
    return 0.5 * (1.0 - cos((TAU*n)/(N-1.0)));
}

//	Sinc function
float sinc(float x) {
    if (x == 0.0) return 1.0;
	return sin(pi*x) / (pi*x);
}


void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;

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

}


#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 2) in float vNTSC_FILTER_FC;
layout(location = 3) in float vNTSC_FILTER_SCF;
layout(location = 4) in float vNTSC_weights[NTSC_FILTER_WIDTH_MAX];
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 2) uniform sampler2D Source;


//	Colorspace conversion matrix for YIQ-to-RGB
const mat3 YIQ2RGB = mat3(1.000, 1.000, 1.000,
                          0.956,-0.272,-1.106,
                          0.621,-0.647, 1.703);

const mat3 RGB2YIQ = mat3(
         0.2989, 0.5959, 0.2115,
         0.5870, -0.2744, -0.5229,
         0.1140, -0.3216, 0.3114);


//	Hann windowing function
float hann(float n, float N) {
    return 0.5 * (1.0 - cos((TAU*n)/(N-1.0)));
}

//	Sinc function
float sinc(float x) {
    if (x == 0.0) return 1.0;
	return sin(pi*x) / (pi*x);
}

#define pi10 pi*10


vec3 ntscdec(vec2 uv ){
   vec2 size = params.SourceSize.xy;
   //	Sample composite signal and decode to YIQ
      vec3 YIQ_processed = vec3(0.0);
      int N = int(NTSC_FILTER_WIDTH);
      for (int n=0; n < N; n++) {
         vec2 pos = uv + vec2(float(n-NTSC_FILTER_MIDDLE) / size.x, 0.0);
         float phase =  TAU * (vNTSC_FILTER_SCF * size.x * pos.x);
         //phase += ( pos.x * 3.14 * 20) ; // rainbow width
         if (NTSC_PHASE_SHIFT > 0.5) phase += ( pos.y * -pi10 ) ; // 45 degree
         //if (NTSC_DOT_CRAWL > 0.5)  phase += (params.FrameCount % 3140) /2.0 ;
         //float phase =  TAU * (vNTSC_FILTER_SCF * size.x * pos.x) + ( pos.y * -pi10 * NTSC_PHASE_SHIFT) 
         // ( pos.y * - 31.4);
         //Just sample luminance via yiq:
            vec3 smp = vec3((texture(Source, pos).rgb * RGB2YIQ).x);
            YIQ_processed += vec3(1.0, cos(phase), sin(phase)) * smp * vNTSC_weights[n];
      }

   vec3 RGB_ori = texture(Source, uv).rgb;
   vec3 YIQ_ori = RGB_ori * RGB2YIQ;

   //ADD artifacted Y and Q.
   vec3 YIQ_result = vec3(YIQ_ori.x, YIQ_ori.yz + YIQ_processed.yz * NTSC_MIX);


  /* se li vogliamo aggiungere come complemento ad 1?
   * tutto il
   * tipo ho y1 = 0.5 -> aggiungo y2 al max fino a 0.5, quindi come una sorta di clamp.
   * oppure partendo dall'opposto. e aggiungendo l'orinale all'ntsc.
   */

// YIQ_result.y = YIQ_ori.y + clamp(YIQ_processed.y, 0.0, (1-YIQ_ori.y)) * NTSC_MIX;
//  YIQ_result.z = YIQ_ori.z + clamp(YIQ_processed.z, 0.0, (1-YIQ_ori.z)) * NTSC_MIX;

//return YIQ_processed * YIQ2RGB;

  return YIQ_result * YIQ2RGB;
}


void main() {
   if (DO_NTSC_ARTIFACTS > 0.5)
      FragColor = vec4(ntscdec(vTexCoord),1.0);
         else
      FragColor = texture(Source, vTexCoord);
   return;
}


