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


#include "includes/blurs.include.slang"
#include "includes/functions.include.slang"

void main() {
   if (DO_BEZEL == 1.0) {
      if (is_useless(texture(Source, vTexCoord))) return;
      
      vec2 res = vec2(params.SourceSize.x, params.SourceSize.y);
      vec2 dir = vec2(0.0,1.0);
      FragColor = blur9(Source, vTexCoord,res,dir);
   }
}
 
 
  
