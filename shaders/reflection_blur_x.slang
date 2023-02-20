#version 450
#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;

layout(location = 0) out vec2 vTexCoord;

#include "includes/functions.include.slang"
void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   if (DO_BEZEL > 0.5)
      vTexCoord = zoom(vTexCoord, BEZEL_REFL_ZOOM);
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;

layout(location = 0) out vec4 FragColor;

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
   
   vec2 coords = zoomout_coords(vTexCoord, BEZEL_BORDER_SIZE , 1.0);
   
   bool skip_condition = (coords.x < 1.0 - c_tolerance && coords.x > c_tolerance && 
                          coords.y < 1.0 - c_tolerance && coords.y > c_tolerance ) ;

   if (skip_condition) {
      FragColor = mark_useless(vec3(0.0));
      return;
   }
      

   vec3 pixel_blur = blur_unroll(BEZEL_REFL_BLUR_MAX,coords, 2.0);

   //Put a gradient shade in the alpha channel
   //This will be used by the next pass as the mix
   //value between the unblurred image and the blurred one
   //This allow to blur less near the content.
      float shade1 = abs(0.0 - coords.x) ;
      float shade2 = abs(1.0 - coords.x) ;
      float shade3 = abs(0.0 - coords.y) ;
      float shade4 = abs(1.0 - coords.y) ;
         
      float shadex = min(shade1, shade2);
      float shadey = min(shade3, shade4);
      
      float shade = min(shadex, shadey);
      
      shade = shade * BEZEL_RFL_BLR_SHD + 0.01;
   
   FragColor = vec4(apply_fuzzy_main_pass(pixel_blur),shade);
   
}
 
 
  
