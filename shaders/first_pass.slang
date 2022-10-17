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
   
   if (DO_OFFSET == 1.0) {
      vec2 offset_r = vec2(floor(OFFSET_R), fract(OFFSET_R)*10)-vec2(10,0.10);
      vec2 offset_g = vec2(floor(OFFSET_G), fract(OFFSET_G)*10)-vec2(10,0.10);
      vec2 offset_b = vec2(floor(OFFSET_B), fract(OFFSET_B)*10)-vec2(10,0.10);
   
      vec2 d = -vec2(global.FinalViewportSize.z,global.FinalViewportSize.w);
      vec3 pixel_offset;
      pixel_offset.r=texture(Source,vTexCoord + offset_r * d).r;
      pixel_offset.g=texture(Source,vTexCoord + offset_g * d).g;
      pixel_offset.b=texture(Source,vTexCoord + offset_b * d).b;

      vec3 pixel_out = texture(Source, vTexCoord).rgb;
      pixel_out = mix(pixel_out,pixel_offset,OFFSET_STRENGTH);
      FragColor = vec4(pixel_out,1.0);
      
   } else {
      
      FragColor = texture(Source, vTexCoord);
      
   }
   
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
 
  
