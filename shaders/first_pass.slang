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

void main() {
   FragColor = texture(Source, vTexCoord);
   
   //Use one of the following to debug:
      //FragColor=vec4(abs(sin(params.FrameCount/3.14/4))); //white fade
      //FragColor=vec4(abs(sin(params.FrameCount/3.14/20)),0.0,0.0,0.0); //red fade
      //FragColor=vec4(1.0);
      //FragColor=vec4(0.38,0.0,1.0,1.0);
      //FragColor=vec4(0.38,0.0,1.0,1.0)*vTexCoord.x;
      //FragColor=vec4(vTexCoord.x); //H bw gradient
      //FragColor=vec4(floor(vTexCoord.x*16)/16); //H bw gradient 16gray
      //FragColor=vec4(floor(vTexCoord.x*64)/64); //H bw gradient 64gray
      //if  (mod(params.FrameCount,100) < 50) FragColor=vec4(0.0) ; else FragColor=vec4(1.0);      
}
 
  
