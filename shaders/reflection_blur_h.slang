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
   vTexCoord = TexCoord ;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D main_pass;

#define SourceTexture main_pass
#define SourceTextureSize global.main_passSize

#include "blooms.slang"
void main() {
   //FragColor = texture(Source, vTexCoord);
   vec2 res = vec2(global.main_passSize.x, global.main_passSize.y);
   vec2 dir = vec2(1.0,0.0);
   FragColor = blur9(main_pass, vTexCoord,res,dir);
}
 
 
  
