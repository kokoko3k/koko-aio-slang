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
   if (DO_SPOT == 1.0) {
      float dasp = global.FinalViewportSize.x/global.FinalViewportSize.y;
      vTexCoord.x = TexCoord.x* dasp - ((0.5 * dasp) - 0.5);
      vTexCoord.y = TexCoord.y;
   }
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

#include "functions.include"
void main() {
   if (DO_SPOT == 1.0)
      FragColor = vec4(gauss_xy(s_center_x, s_center_y, s_size, s_power, 0.0, 10.0));
}


