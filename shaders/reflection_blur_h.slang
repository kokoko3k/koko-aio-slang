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
layout(set = 0, binding = 1) uniform sampler2D main_pass;
layout(set = 0, binding = 2) uniform sampler2D isrotated_pass;

#include "includes/blurs.include.slang"
#include "includes/functions.include.slang"

#define c_tolerance 0.1

void main() {

   if (DO_BEZEL == 1.0) {
      bool is_rotated = texture(isrotated_pass,vec2(0.5,0.5)).r > 0.5;

      /* Calculate the internal area (the one which is not mirrored)
         so that we can skip blurring it:
      */
         vec2 ar_box;
         if (!is_rotated) {
            //Width of the aspect corrected box zoomed as requested by the bezel settings:                                  
            ar_box.x = global.FinalViewportSize.z*global.FinalViewportSize.y*get_in_aspect() * (1+BEZEL_INNER_ZOOM-c_tolerance) ; 
            //Height zoomed as requested by bezel settings:
            ar_box.y = 1+BEZEL_INNER_ZOOM-c_tolerance;
               } else {
            ar_box.y = global.FinalViewportSize.z*global.FinalViewportSize.y/get_in_aspect() * (1+BEZEL_INNER_ZOOM-c_tolerance) ; 
            ar_box.x= 1+BEZEL_INNER_ZOOM-c_tolerance;
         }
   
         //start_point is the middle of the screen minut half the content width
         vec2 start_point = vec2(0.5 - (ar_box.x*0.5), 0.5 - (ar_box.y*0.5));
         vec2 end_point =   vec2(0.5 + (ar_box.x*0.5), 0.5 + (ar_box.y*0.5));


      //Now we can skip the internal area or the black one as already marked by main_pass:
      bool skip_condition =(vTexCoord.x > start_point.x  && vTexCoord.x < end_point.x &&
                           vTexCoord.y > start_point.y && vTexCoord.y < end_point.y) ||
                           is_outer_frame(texture(main_pass,vTexCoord));


      if (skip_condition) {
         FragColor = mark_useless(vec3(0.0));
         return;
      }
         
         vec2 res = vec2(params.SourceSize.x, params.SourceSize.y);
         vec2 dir = vec2(1.0,0.0);
         FragColor = blur9(main_pass, vTexCoord,res,dir);
   }

   
}
 
 
  
