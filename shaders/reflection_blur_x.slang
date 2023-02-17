#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vWarp_vexp;
layout(location = 2) out vec2 vWarp_arg2;

#include "includes/functions.include.slang"
void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   if (DO_BEZEL > 0.5)
      vTexCoord = zoom(vTexCoord, BEZEL_REFL_ZOOM);

   //Precalc some Curvature/Warp values:
      vWarp_vexp = 1.0/ (1 + (vec2(GEOM_WARP_X, GEOM_WARP_Y) * 0.2)) ;
      vWarp_arg2 = 1.0 - pow(vec2(0.29289321881345247559915563789515), vWarp_vexp );
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;

layout(location = 0) out vec4 FragColor;
layout(location = 1) in vec2 vWarp_vexp;
layout(location = 2) in vec2 vWarp_arg2;

layout(set = 0, binding = 1) uniform sampler2D first_pass;

#define SourceTexture first_pass
#define SourceTextureSize global.first_passSize

#include "includes/functions.include.slang"

#define c_tolerance 0.051

vec3 blur_unroll(float Size, vec2 co,float lod) {
   Size = Size * NEW_SCALEMOD_X;
   vec3 color;
   vec2 d = SourceTextureSize.zw * Size;
   color =  textureLod( SourceTexture, co + d * vec2(-1.0,  1.0 )  ,lod).rgb ;
   color += textureLod( SourceTexture, co + d * vec2( 1.0,  1.0 )  ,lod).rgb ;
   color += textureLod( SourceTexture, co + d * vec2(-1.0,  -1.0 ) ,lod).rgb ;
   color += textureLod( SourceTexture, co + d * vec2( 1.0,  -1.0 ) ,lod).rgb ;
   return color / 4.0;
}

void main() {
   if (DO_BEZEL == 0.0) return;
   
   vec2 coords_curved = vTexCoord;
   if (DO_CURVATURE == 1.0) {
      if ((GEOM_WARP_X > 0.0) || (GEOM_WARP_Y > 0.0))
            coords_curved = Warp_fast(coords_curved, vWarp_vexp, vWarp_arg2); //coords_curved = Warp(coords_curved,GEOM_WARP_X,GEOM_WARP_Y);
   }

   coords_curved = zoomout_coords(coords_curved, BEZEL_BORDER_SIZE , 1.0);
   
   bool skip_condition = (coords_curved.x < 1.0 - c_tolerance && coords_curved.x > c_tolerance && 
                          coords_curved.y < 1.0 - c_tolerance && coords_curved.y > c_tolerance ) ;

   if (skip_condition) {
      FragColor = mark_useless(vec3(0.0));
      return;
   }
      

   vec3 pixel_blur = blur_unroll(BEZEL_REFL_BLUR_MAX,coords_curved, 2.0);

   //Put a gradient shade in the alpha channel
   //This will be used by the next pass as the mix
   //value between the unblurred image and the blurred one
   //This allow to blur less near the content.
      float shade1 = abs(0.0 - coords_curved.x) ;
      float shade2 = abs(1.0 - coords_curved.x) ;
      float shade3 = abs(0.0 - coords_curved.y) ;
      float shade4 = abs(1.0 - coords_curved.y) ;
         
      float shadex = min(shade1, shade2);
      float shadey = min(shade3, shade4);
      
      float shade = min(shadex, shadey);
      
      shade = shade * BEZEL_RFL_BLR_SHD + 0.01;
   
   FragColor = vec4(apply_fuzzy_main_pass(pixel_blur),shade);
   
}
 
 
  
