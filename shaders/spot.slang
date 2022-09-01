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
   if (DO_SPOT == 1.0) {
      if (border_needed()) {
         //vTexCoord = TexCoord;
         float in_aspect = get_in_aspect();
         float spot_offset = 0.5 - s_center_x  ; //;* in_aspect * 0.5;
         float dasp = global.FinalViewportSize.y/global.FinalViewportSize.x;
         vTexCoord.x = TexCoord.x* dasp - ((spot_offset * dasp) - spot_offset);
         vTexCoord.x = vTexCoord.x* in_aspect - ((spot_offset * in_aspect) - spot_offset);
      }
   }
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#include "functions.include"
void main() {
   if (DO_SPOT == 1.0) {
      float gaussxy = gauss_xy(s_center_x, s_center_y, s_size, s_power, 0.0, 10.0);
      FragColor = vec4(gaussxy,gaussxy,gaussxy,1.0);
   } else {
        return;
    }
}


