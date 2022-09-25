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

#include "functions.include.slang"

void main() {
   vec2 coords = vTexCoord;
   if (DO_BEZEL == 1.0) {
      coords = zoom(vTexCoord,1-BEZEL_IMAGE_BORDER);
      if (coords.x < 0.0 || coords.y < 0.0 || coords.y > 1.0 || coords.x > 1.0) {
         FragColor = vec4(0.0);
         return;
      }
   }
   vec3 pixel_in = texture(Source, coords).rgb;
   FragColor = vec4(pixel_in.rgb,1.0);
}
 
  
