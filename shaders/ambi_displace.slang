#version 450
#include "config.inc"
#define eps 1e-8

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;


#include "functions.include"
void main()
{
   gl_Position = global.MVP * Position;
   //vTexCoord.x = TexCoord.x * 0.75 + (1-0.75)/2.0;
   //vTexCoord.y = TexCoord.y;
vTexCoord = TexCoord;
   //vTexCoord = (get_scaled_coords(TexCoord) + TexCoord) / 2.0;
   //vTexCoord = get_scaled_coords(TexCoord,params.OutputSize);
//vTexCoord = get_scaled_coords(TexCoord,global.FinalViewportSize );
   //global.FinalViewportSize 
   
   
   
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Original;
layout(set = 0, binding = 3) uniform sampler2D main_pass;

#include "functions.include"


vec3 main_wrap(){

   float myborder = 0.125; //20% border to be displaced
   vec2 newcoords = vTexCoord;
   vec3 pixel_out;
   float mydiv;
   float myoffset;

   if (!is_rotated()) {
      mydiv = vTexCoord.x / myborder;
      myoffset = (1.0-myborder) * floor(mydiv);

      if (vTexCoord.x < 0.5)
      newcoords.x = newcoords.x - (  myborder * floor(mydiv) ) ;
         else
      newcoords.x = (1 - myborder) +  ( newcoords.x -   (myborder*floor(mydiv))  )  ;
      
      return texture(Original, newcoords).rgb;
   }
   
   //Is rotated
      mydiv = vTexCoord.y / myborder;
      myoffset = (1.0-myborder) * floor(mydiv);

      if (vTexCoord.y < 0.5)
      newcoords.y = newcoords.y - (  myborder * floor(mydiv) ) ;
         else
      newcoords.y = (1 - myborder) +  ( newcoords.y -   (myborder*floor(mydiv))  )  ;   
      return texture(Original, newcoords).rgb;
   

   
   //Push sat and brightness:
   /*float l = length(pixel_out);
   float sat = 2.0;
   float bright = 1.25;
   pixel_out =  normalize( pow(pixel_out.rgb + vec3(eps), vec3(sat)))*l * bright  ;
   pixel_out*=bright;
  */
   //return pixel_out;
}

void main() {
/*   if (DO_AMBILIGHT == 1.0) {
      bool is_border = false;
      if (border_needed()) {
         bool b_is_rotated = is_rotated();
         bool is_outside_x = ((vTexCoord.x > 1.0 ) || (vTexCoord.x < 0.0 ) );
         bool is_outside_y = ((vTexCoord.y > 1.0 ) || (vTexCoord.y < 0.0 ) );
         is_border = (b_is_rotated && is_outside_y) || (!b_is_rotated && is_outside_x);
      }
      
      if (is_border)
          FragColor = vec4(0.0);
            else
          FragColor = vec4(main_wrap(),1.0);
      } else {
         return;
      }
      
*/
   vec4 psample = texture(main_pass,vTexCoord);
   bool IsOuterFrame;
   vec4 pixel_out;
   if ( border_needed() ) {
        IsOuterFrame = is_outer_frame(psample);
        if (IsOuterFrame)
            pixel_out = mark_outer_frame(vec3(0.0));
                else
            pixel_out = vec4(main_wrap().rgb,1.0);
   }
   
FragColor = pixel_out;
      
   //if (DO_AMBILIGHT == 1.0)
   //FragColor = vec4(main_wrap(),1.0);
      
}


