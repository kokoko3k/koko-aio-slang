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


float warp_x(float coord_x, float strength){
   //Adapted from crt-hyllian-curvature,
   //Takes a coordinate, returns it warped
   float curvedCoord = coord_x * 2.0 - 1.0;
   float curvedCoordsDistance = abs(coord_x-0.5)*2;
   curvedCoord = curvedCoord / curvedCoordsDistance;
   curvedCoord *= (1.0 - pow(1.0-curvedCoordsDistance,1.0/strength));
   /*
   curvedCoord = curvedCoord * (1.0- pow ((1.0-(curvedCoordsDistance/1.4142135623730950488016887242097)), (1.0/(1.0+strength*0.2))));
   curvedCoord = curvedCoord / (1.0-pow((0.29289321881345247559915563789515),(1.0/((1.0)+strength*0.2))));
   curvedCoord = curvedCoord * 0.5 + 0.5;
   */
   curvedCoord = curvedCoord * 0.5 + 0.5;
   return curvedCoord;
}


void main() {

   vec2 warp_coords = vec2(warp_x(vTexCoord.x,0.7),vTexCoord.y);
   FragColor = vec4(texture(Source, warp_coords).xyz,1.0);


//   FragColor = vec4(texture(Original, vTexCoord).xyz,1.0);
}
