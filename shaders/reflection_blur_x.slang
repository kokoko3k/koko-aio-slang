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
layout(set = 0, binding = 2) uniform sampler2D avglum_pass;

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


vec2 mirrored_repeat(vec2 co, float crop) {
   //Don't try to unbranch me, it is a matter of 1/1000.
   float cmin = 0.0 + crop ;
   float cmax = 1.0 - crop ; 
   if (co.x < cmin )
      co.x = 2*cmin - co.x;
   if (co.y < cmin)
      co.y = 2*cmin - co.y;
   if (co.x > cmax )
      co.x = 2*cmax - co.x;
   if (co.y > cmax )
      co.y = 2*cmax - co.y;
   return co;
}

void main() {
   if (DO_BEZEL == 0.0) return;
   
   vec2 coords = zoomout_coords(vTexCoord, BEZEL_BORDER_SIZE, 1.0);
   vec2 coords_zoomedout = coords;

   bool skip_condition = (coords.x < 1.0 - c_tolerance && coords.x > c_tolerance && 
                          coords.y < 1.0 - c_tolerance && coords.y > c_tolerance ) ;

   if (skip_condition) {
      FragColor = mark_useless(vec3(0.0));
      return;
   }
       
   float coords_crop_point = 0.0;
   //* set the mirror point according to the dynamic zoom?
      if (DO_DYNZOOM == 1.0) {
         coords_crop_point = get_dyn_zoom(avglum_pass) - 1.0;
         coords_crop_point = coords_crop_point * 0.5;
      }

   //Do mirrored_repeat 
   coords = mirrored_repeat(coords, coords_crop_point);
  
   //Put a gradient shade in the alpha channel
   //This will be used in this and the next
   //pass to modulate the blur radius.
   //This allow to blur less near the content.
      float shade1 = abs(     coords_zoomedout.x - coords_crop_point );
      float shade2 = abs( 1 - coords_zoomedout.x - coords_crop_point );
      float shade3 = abs(     coords_zoomedout.y - coords_crop_point );
      float shade4 = abs( 1 - coords_zoomedout.y - coords_crop_point );
        
      shade1 = min(shade1, shade2);
      shade2 = min(shade3, shade4);
      float shade  = min(shade1, shade2) * 1/(BEZEL_BORDER_SIZE * 0.5) ;
      shade = shade - BEZEL_RFL_BLR_SHD;
      
      //Clamp to min 0.006 because anything lower will cause the next pass to think
      //the pixel is useless.
      shade = clamp(shade, 0.006, 1.0);     
      
   vec3 pixel_blur = blur_unroll(BEZEL_REFL_BLUR_MAX * shade, coords, 2.0);   

   FragColor = vec4(apply_fuzzy_main_pass(pixel_blur),shade);
   
}
 
 
  
