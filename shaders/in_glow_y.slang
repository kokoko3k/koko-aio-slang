#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out float vIN_GLOW_H;

void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;  
   vIN_GLOW_H = IN_GLOW_H / NEW_SCALEMOD_Y; //Make it resolution independent.
}


#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float vIN_GLOW_H;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 5) uniform sampler2D shift_and_bleed_pass;
layout(set = 0, binding = 6) uniform sampler2D Source;



#include "includes/functions.include.slang" 

vec3 glow_blur_bias(sampler2D source_tex, vec2 co, vec3 pixel_glowed, float bias){
   vec3 pixel_source = texture(source_tex, co).rgb;
   // Since I moved from one pass blur for glow to 2 passes (x,y), I've had to
   // move the pow to IN_GLOW_GAMMA in the previous pass, so pow-ering it
   // again here, is not needed.
   //       pixel_source  = pow(pixel_source,vec3(IN_GLOW_GAMMA)) * IN_GLOW_POWER;
   pixel_source  = pixel_source * IN_GLOW_POWER;
   
   vec3 glow_light = clamp((pixel_glowed - pixel_source) * IN_GLOW_AMOUNT, 0.0, 1.0);

   /* powering glow_light is fine when not dealing with scanline minimum thickness,
    * but when the scanline shape gets smaller, it kinda produces a visive
    * pow(x,2) by its own; in that case powering glow_light make things worse.
    * It makes sense, because we are emulating the light spread twice.
    * FIXME: How to deal with this?
    */
   vec3 proper_glow = glow_light * glow_light + pixel_source;

   return mix(proper_glow, pixel_glowed, max(0.0, bias));   

}


void main() { 
   if (DO_IN_GLOW == 0.0) return;
   
   //apply just gamma and power for tighter blurs and exit:
   if (IN_GLOW_W >= GLOW_SHARP_MAX && IN_GLOW_H >= GLOW_SHARP_MAX) {
      FragColor = vec4( glow_dumb(Source, IN_GLOW_POWER, IN_GLOW_GAMMA, vTexCoord), 1.0);
      return;
   }

   vec3 pixel_glowed = texture(Source, vTexCoord).rgb;
   pixel_glowed = blur9_y(Source, vTexCoord, params.SourceSize.xy, vIN_GLOW_H) * IN_GLOW_POWER;

   if (IN_GLOW_BIAS < IN_GLOW_BIAS_MAX && (IN_GLOW_W < GLOW_SHARP_MAX || IN_GLOW_H < GLOW_SHARP_MAX) ) {
           pixel_glowed = glow_blur_bias(shift_and_bleed_pass, vTexCoord, pixel_glowed, IN_GLOW_BIAS);
   }

   //pre-gamma if needed by halo.
   if (DO_HALO == 1.0)
      pixel_glowed = pow(pixel_glowed, vec3(HALO_GAMMA));
   
   FragColor = vec4(pixel_glowed,1.0);
}

