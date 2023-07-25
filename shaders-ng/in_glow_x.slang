#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;  
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 5) uniform sampler2D shift_and_bleed_pass;

layout(set = 0, binding = 6) uniform sampler2D shift_and_bleed_passFeedback;


#include "includes/functions.include.slang" 


//https://lisyarus.github.io/blog/graphics/2023/02/24/blur-coefficients-generator.html
//sono uguali al vecchio così:
//raggio 4
//sigma 1.7 

//fvedi pure https://www.shadertoy.com/view/4sGcRW
//e vedi che 

/*float Gaussian( float x )
{
x=clamp(x,-1.0,1.0);
    float c=3.14*0.5;
    return cos(1.5*x)*cos(1.5*x)*1.0;
	const float alpha = 5.0;
	const float expv = exp(-alpha); //note: radius = 1.0
    return max(0.0, (exp(-alpha * x * x) - expv));
    //return max(0.0, (exp(-alpha * x * x) - expv) / (1.0-expv)); //note: normalisation-factor to always get f(0)=1
}

const int SAMPLE_COUNT = 4;

const float OFFSETS[4] = float[4](
    -2.1961930637455005,
    -0.43006286395671545,
    1.3004294284587026,
    3
);

const float WEIGHTS[4] = float[4](
    0.12159651477371808,
    0.5292123790688621,
    0.3253347133831891,
    0.02385639277423076
);



#define BLURDIRECTION vec2(1,0)
 //blur_h_new(shift_and_bleed_pass, vTexCoord, global.flick_and_noise_passSize.xy, IN_GLOW_W_ADAPTED)
vec3 blur_h_new(sampler2D sourceTexture, vec2 pixelCoord, vec2 sourcesize, float sharpness)
{
    vec3 result = vec3(0.0);
    vec2 size = sourcesize * sharpness;
    for (int i = 0; i < SAMPLE_COUNT; ++i)
    {
        vec2 offset = BLURDIRECTION * OFFSETS[i] / size;
        float weight = WEIGHTS[i];
        result += texture(sourceTexture, pixelCoord + offset).rgb * weight;
    }
    return result;
}
*/

void main() { 
   if (DO_IN_GLOW == 0.0) {
      //Delta render?
      if (DELTA_RENDER == 1.0) {
         float DR_unchanged = float( textureLod(shift_and_bleed_pass,         vTexCoord, DELTA_RENDER_CHECK_AREA).rgb == 
                                     textureLod(shift_and_bleed_passFeedback, vTexCoord, DELTA_RENDER_CHECK_AREA).rgb);
         FragColor = vec4(0.0,0.0,0.0,DR_unchanged); 
         return;
      }
   };

   //Don't do anything if IN_GLOW_W and IN_GLOW_H are over the upper limit
      if (IN_GLOW_W >= GLOW_SHARP_MAX && IN_GLOW_H >= GLOW_SHARP_MAX) {
         vec4 passthrough = texture(shift_and_bleed_pass, vTexCoord);
         //Delta render?
         if (DELTA_RENDER == 1.0) {
            float DR_unchanged = float( textureLod(shift_and_bleed_pass,         vTexCoord, DELTA_RENDER_CHECK_AREA).rgb == 
                                        textureLod(shift_and_bleed_passFeedback, vTexCoord, DELTA_RENDER_CHECK_AREA).rgb);
            FragColor = vec4(passthrough.rgb, DR_unchanged);
            return;
         }
         FragColor = passthrough;
         return;
      }

      
   float IN_GLOW_W_ADAPTED = IN_GLOW_W;
   //Auto calc glow sharpness via IN_GLOW_SPREAD
      if (IN_GLOW_W <= 0.00001)
         IN_GLOW_W_ADAPTED = IN_GLOW_SPREAD * IN_GLOW_SHARPNESS_SPREAD_RATIO_W;


   //Here lies the blur modifier from ntsc pass to glow.
   //I'm not expecting any performance hit, 
   //since the lookup should have been cached already or will serve so.
   float ntsc_artifacts = texture(shift_and_bleed_pass, vTexCoord).a;

   //To debug ntsc artifacts mask:
      if (DO_NTSC_ARTIFACTS + NTSC_SHOW_ARTF_MASK > 1.5) {
         FragColor = vec4(ntsc_artifacts);
         return;
      }
      
   //finally "add" them to the configured sharpness (-> less blur)
      //IN_GLOW_W_ADAPTED = IN_GLOW_W_ADAPTED +  DO_NTSC_ARTIFACTS * ((1-ntsc_artifacts) * NTSC_ARTF_NOBLUR);

   //don't allow lower values that look bad:
      IN_GLOW_W_ADAPTED = max(IN_GLOW_W_ADAPTED, MIN_IN_GLOW_SHARP);

   //Make it resolution independent.
      IN_GLOW_W_ADAPTED = IN_GLOW_W_ADAPTED / NEW_SCALEMOD_X;

   //Delta render?
      float DR_unchanged = 0.0;
      if (DELTA_RENDER == 1.0) {
         //Keep track of changed pixels to speedup rendering in final pass   
         DR_unchanged = float( textureLod(shift_and_bleed_pass,         vTexCoord, DELTA_RENDER_CHECK_AREA).rgb == 
                               textureLod(shift_and_bleed_passFeedback, vTexCoord, DELTA_RENDER_CHECK_AREA).rgb);
      }
      

      
   //Finally blur horizontally 
   if (IN_GLOW_W < GLOW_SHARP_MAX) {
         FragColor = vec4( blur9_x(shift_and_bleed_pass, vTexCoord, global.flick_and_noise_passSize.xy, IN_GLOW_W_ADAPTED), DR_unchanged);
         //FragColor = vec4( blur_h_new(shift_and_bleed_pass, vTexCoord, global.flick_and_noise_passSize.xy, IN_GLOW_W_ADAPTED), DR_unchanged);
   }else{
      FragColor = texture(shift_and_bleed_pass, vTexCoord, DR_unchanged);
   }
   
}

