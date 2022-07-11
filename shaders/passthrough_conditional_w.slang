#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Source;

//We will not use the scaled texture if it is already big,
//so, don't even do a lookup if not needed.
   void main() {
      if (params.OriginalSize.x > MIN_W) {
         FragColor = vec4(0.0);
      } else {
         FragColor = vec4(texture(Source, vTexCoord).xyz,1.0);
      }
   }
