#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 r_offset;
layout(location = 2) out vec2 g_offset;
layout(location = 3) out vec2 b_offset;

#include "functions.include.slang"

#define OFFSET_DIRECTIONS 8

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   if (DO_OFFSET == 1.0) {
      float in_aspect = get_in_aspect();
      vec2 spr_scale = 10 * vec2(get_in_aspect(),1.0);
      float spr_radius = min(params.SourceSize.z, params.SourceSize.w);
      r_offset = circles(OFFSET_R, spr_radius, in_aspect, OFFSET_DIRECTIONS);
      g_offset = circles(OFFSET_G, spr_radius, in_aspect, OFFSET_DIRECTIONS);
      b_offset = circles(OFFSET_B, spr_radius, in_aspect, OFFSET_DIRECTIONS);
   }
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 r_offset;
layout(location = 2) in vec2 g_offset;
layout(location = 3) in vec2 b_offset;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 2) uniform sampler2D Source;


void main() { 
   if (DO_OFFSET == 1.0) {   
      vec2 d = -vec2(global.FinalViewportSize.z,global.FinalViewportSize.w);
      vec3 pixel_offset;
      pixel_offset.r=texture(Source,vTexCoord + r_offset * d).r;
      pixel_offset.g=texture(Source,vTexCoord + g_offset * d).g;
      pixel_offset.b=texture(Source,vTexCoord + b_offset * d).b;

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
 
  
