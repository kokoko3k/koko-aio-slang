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
   //vTexCoord = TexCoord;
   //vTexCoord = (get_scaled_coords(TexCoord) + TexCoord) / 2.0; 
   vTexCoord = get_scaled_coords(TexCoord);
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Original;

#include "functions.include"


vec3 main_wrap(){

   float myborder = 0.025; //20% border to be displaced
   vec2 newcoords = vTexCoord;
   float mydiv = vTexCoord.x / myborder;
   float myoffset = (1.0-myborder) * floor(mydiv);
   if (vTexCoord.x < 0.5)
   newcoords.x = newcoords.x - (  myborder * floor(mydiv) ) ;
      else
   newcoords.x = (1 - myborder) +  ( newcoords.x-   (myborder*floor(mydiv))  )  ;
   vec3 pixel_out = texture(Original, newcoords).rgb;

   //Push sat and brightness:
   /*float l = length(pixel_out);
   float sat = 2.0;
   float bright = 1.25;
   pixel_out =  normalize( pow(pixel_out.rgb + vec3(eps), vec3(sat)))*l * bright  ;
   pixel_out*=bright;
  */
   return pixel_out;
}

void main() {
   if (DO_AMBILIGHT == 1.0) {
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
}


