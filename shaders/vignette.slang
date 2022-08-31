#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

#include "functions.include"
void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   float aspect_prev = (params.SourceSize.y / params.SourceSize.x);
   if (border_needed() ) {
      vTexCoord.x = vTexCoord.x * aspect_prev - ((0.5 * aspect_prev) - 0.5);
      float in_aspect = get_in_aspect();
      vTexCoord.x = vTexCoord.x * in_aspect - ((0.5 * in_aspect) - 0.5);
   } else {
      vTexCoord.x = vTexCoord.x * aspect_prev - ((0.5 * aspect_prev) - 0.5);
      float dasp = global.FinalViewportSize.x/global.FinalViewportSize.y;
      vTexCoord.x = (vTexCoord.x* dasp - ((0.5 * dasp) - 0.5)) ;
   }
}






#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#include "functions.include"
void main() {
   if (DO_VIGNETTE == 1.0) {
      float gaussxy = gauss_xy(0.0, 0.0, v_size, v_power, 0.0, 1.0);
      FragColor = vec4(gaussxy,gaussxy,gaussxy,1.0);
   }
}
 
  
