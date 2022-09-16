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
   vTexCoord =TexCoord ;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D main_pass;

#define SourceTexture main_pass
#define SourceTextureSize global.main_passSize

#include "blooms.slang"
#include "functions.include"
void main() {
   
 /*  vec2 coords = vTexCoord;
   float zoom2 = 0.5 ;
   coords=zoom(vTexCoord,zoom2);
   vec4 pixel_out = vec4(1.0);
   //skip a slice.
   float in_aspect = get_in_aspect();
   float out_aspect = global.FinalViewportSize.x / global.FinalViewportSize.y;
  
      // calculate the width of the content  
      //we know that it fills the screen vertically, so we now how much is high:
      float content_h = global.FinalViewportSize.y;
      //we know its aspect, so we know how much is wide
      float content_w = content_h * in_aspect;
      //We need its width in 0..1 range, so calculate it in function of the maximum width:
            content_w = content_w / global.FinalViewportSize.x; 
  
  
  content_w *= zoom2;
  
  float slice_size = (1-(in_aspect/out_aspect))/2.0 ;
  slice_size *= zoom2;
  
  float offset_size = 1.0 - (0.5+(content_w/2.0)+(slice_size*2));
  
  //before offset_size, we can pass pixels, as it is the mirrored picture:
 //  if ( vTexCoord.x < offset_size) {
 //     FragColor = texture(main_pass, coords);
 //     return;
 //  }
   
  //from offset size, we need to skip slice_size pixels
//   if ( vTexCoord.x > offset_size  && vTexCoord.x < offset_size + (slice_size*2) ) {
      //coords = vec2(0.0);
      //FragColor = texture(main_pass, vec2(coords.x-offset_size,coords.y));
 //     FragColor = texture(main_pass, vec2(coords.x -  (slice_size*4)  ,coords.y));
 //     return;
 //  }

 
 
 
*/ 
/*
 
 vec2 coords = vTexCoord;
 float in_aspect = get_in_aspect();
 float out_aspect = global.FinalViewportSize.x / global.FinalViewportSize.y;
 coords.x = zoom(coords,out_aspect/in_aspect*1.02).x;  //add 2% more to cut black borders (FIXME: where does it come from, anyway?)
 //FragColor = texture(main_pass, coords);
 
*/


   if (DO_BEZEL == 1.0) {
      vec2 res = vec2(global.main_passSize.x, global.main_passSize.y);
      vec2 dir = vec2(1.0,0.0);
      FragColor = blur9(main_pass, vTexCoord,res,dir);
   }

}
 
 
  
