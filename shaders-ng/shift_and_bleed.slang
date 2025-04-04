#version 450
#include "config.inc"

#define RGB_SHIFT_RANGE 20

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vR_offset;
layout(location = 2) out vec2 vG_offset;
layout(location = 3) out vec2 vB_offset;

#include "includes/functions.include.slang"

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;  
   
   if (DO_SHIFT_RGB == 1.0) {
      vR_offset=-vec2(DECON_RX, DECON_RY) * vec2(NEW_SCALEMOD_X, NEW_SCALEMOD_Y) / global.upscale_passSize.xy ;
      vG_offset=-vec2(DECON_GX, DECON_GY) * vec2(NEW_SCALEMOD_X, NEW_SCALEMOD_Y) / global.upscale_passSize.xy ;
      vB_offset=-vec2(DECON_BX, DECON_BY) * vec2(NEW_SCALEMOD_X, NEW_SCALEMOD_Y) / global.upscale_passSize.xy ;
   }

}


#pragma stage fragment
#include "includes/functions.include.slang"
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vR_offset;
layout(location = 2) in vec2 vG_offset;
layout(location = 3) in vec2 vB_offset;

layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 1) uniform sampler2D upscale_pass;



vec3 deconvergence_shadow(vec2 coords, sampler2D in_texture, vec3 source_pixel) {
      //Emulates deconvergence or shadowing for dot matrix screens like Gameboy.
      //Since both effects should not coexist in real life, we use a singe function for both.
      //The function stays more or less the same, but rgb offsets calculated in vertex shader
      //will be the same for shadow mode. Hopefully shader texture cache will take care of
      //multiple sampling for the same tex coords.
   
      vec3 pixel_offsetted;
      //Since we are sampling from a "clamp-to-border" texture, ensure we've no black bleeding
      //by clamping the texture coords
      //Removed, since shader chain changed, and this is now useless (?) WARNING <----
      //coords = clamp(coords,params.SourceSize.zw*1 ,1.0-params.SourceSize.zw);

      vec2 R_offset=vR_offset;
      vec2 G_offset=vG_offset;
      vec2 B_offset=vB_offset;


      // Edge defocus:
      float dist_from_edge = distance_from_edge_linear(coords, EDGE_DEFOCUS_AREA_INV);
      float offset_multiplier = mix(EDGE_DEFOCUS, 1.0, dist_from_edge);
      R_offset *= offset_multiplier;
      G_offset *= offset_multiplier;
      B_offset *= offset_multiplier;

      pixel_offsetted.r=texture(in_texture,coords + R_offset).r;
      pixel_offsetted.g=texture(in_texture,coords + G_offset).g;
      pixel_offsetted.b=texture(in_texture,coords + B_offset).b;
     
      return mix(source_pixel.rgb, pixel_offsetted, OFFSET_STRENGTH);
     
}

void main() {
   #ifndef D3D_WORKAROUND
      if (fps_halver_is_skipped_frame())
         return;
   #endif
   vec3 pixel_out;

   pixel_out.rgb = texture(upscale_pass, vTexCoord).rgb;

   //... and shift
   if (DO_SHIFT_RGB > 0.5 )
      pixel_out.rgb = deconvergence_shadow(vTexCoord, upscale_pass, pixel_out.rgb);


   pixel_out.rgb = max(vec3(0.0), pixel_out.rgb);  //make sure everything is over 0.0

   pixel_out.rgb = pow(pixel_out.rgb, vec3(IN_GLOW_GAMMA)); //apply gamma in 
   
   FragColor.rgb = pixel_out.rgb;
}
