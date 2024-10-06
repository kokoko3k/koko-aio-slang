#version 450
#include "config.inc"

#define RGB_SHIFT_RANGE 20

const mat3 mat3_RGB2YIQ = mat3(
   0.2989,  0.5959,  0.2115,
   0.5870, -0.2744, -0.5229,
   0.1140, -0.3216,  0.3114);

const mat3 mat3_YIQ2RGB = mat3(
   1.0,     1.0,     1.0,
   0.956,  -0.2720, -1.1060,
   0.6210, -0.6474,  1.7046);

const mat3 mat3_RGB2YUV = mat3(
   0.299,     0.587,     0.114,
   -0.14713, -0.28886,   0.436,
   0.615,    -0.514991, -0.10001);

const mat3 mat3_YUV2RGB = mat3(
   1.000, 0.000,   1.13983,
   1.000,-0.39465,-0.58060,
   1.000, 2.03211, 0.00000);


//https://www.sciencedirect.com/topics/computer-science/color-subcarrier
const vec3 bandwidths_ntsc = vec3(4.2, 1.5, 0.5); //yiq
const vec3 bandwidths_pal = vec3(5.0, 1.3, 1.3);  //yuv

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vR_offset;
layout(location = 2) out vec2 vG_offset;
layout(location = 3) out vec2 vB_offset;
layout(location = 4) out float vDo_shadow_mode;
layout(location = 5) out float vDecon_or_JustShadow;
layout(location = 6) out float vShow_artifact_mask;
layout(location = 7) out vec3  vBandwidths;
layout(location = 8) out mat3  vmat3_RGB2XXX;
// 8 and 9 taken by mat3 
layout(location = 11) out mat3  vmat3_XXX2RGB;


#include "includes/functions.include.slang"

void main()
{
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord ;  
   
   //...to tell fragment shader if dot matrix feature requests shadows.
      vDo_shadow_mode = float(DOT_M_SHADOW_STR + DO_DOT_MATRIX > 1 + eps);
   
   //Shadow mode disables deconvergence, they do not coexist in real life.
   if (vDo_shadow_mode == 1.0) {
      vR_offset = vec2(DOT_M_SHADOW_OFF, abs(DOT_M_SHADOW_OFF));
      vG_offset = vR_offset;
      vB_offset = vR_offset;
      vec2 d = -params.OutputSize.zw * 0.5;
      vR_offset *= d;
      vG_offset *= d;
      vB_offset *= d;
   } else if (DO_SHIFT_RGB == 1.0) {
      vR_offset=-vec2(DECON_RX, DECON_RY) * vec2(NEW_SCALEMOD_X, NEW_SCALEMOD_Y) / global.upscale_passSize.xy ;
      vG_offset=-vec2(DECON_GX, DECON_GY) * vec2(NEW_SCALEMOD_X, NEW_SCALEMOD_Y) / global.upscale_passSize.xy ;
      vB_offset=-vec2(DECON_BX, DECON_BY) * vec2(NEW_SCALEMOD_X, NEW_SCALEMOD_Y) / global.upscale_passSize.xy ;
   }
   
   //Precalc some conditions:
   bool do_shadow = (DO_DOT_MATRIX == 1.0 && DOT_M_SHADOW_STR > 0.0);
   vDecon_or_JustShadow =  float(DO_SHIFT_RGB > 0.0 || do_shadow    );
   vShow_artifact_mask = float(NTSC_SHOW_ARTF_MASK + DO_NTSC_ARTIFACTS == 2.0);
   
   if (SAT_BLEED_PAL == 1.0) {
      vmat3_RGB2XXX = mat3_RGB2YUV;
      vmat3_XXX2RGB = mat3_YUV2RGB;
      vBandwidths = bandwidths_pal;
   } else {
      vmat3_RGB2XXX = mat3_RGB2YIQ;
      vmat3_XXX2RGB = mat3_YIQ2RGB;
      vBandwidths = bandwidths_ntsc;      
   }
   
}


#pragma stage fragment
#include "includes/functions.include.slang"
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vR_offset;
layout(location = 2) in vec2 vG_offset;
layout(location = 3) in vec2 vB_offset;
layout(location = 4) in float vDo_shadow_mode;
layout(location = 5) in float vDecon_or_JustShadow;
layout(location = 6) in float vShow_artifact_mask;
layout(location = 7) in vec3  vBandwidths;
layout(location = 8) in mat3  vmat3_RGB2XXX;
// 9 and 10 taken by mat3 
layout(location = 11) in mat3  vmat3_XXX2RGB;

layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 1) uniform sampler2D upscale_pass;




vec4 deconvergence_shadow(vec2 coords, sampler2D in_texture, vec4 source_pixel) {
      //Emulates deconvergence or shadowing for dot matrix screens like Gameboy.
      //Since both effects should not coexist in real life, we use a singe function for both.
      //The function stays more or less the same, but rgb offsets calculated in vertex shader
      //will be the same for shadow mode. Hopefully shader texture cache will take care of
      //multiple sampling for the same tex coords.
   
      vec3 pixel_offsetted;
      //Since we are sampling from a "clamp-to-border" texture, ensure we've no black bleeding
      //by clamping the texture coords
      coords = clamp(coords,params.SourceSize.zw*1 ,1.0-params.SourceSize.zw);
      
      vec2 R_offset=vR_offset;
      vec2 G_offset=vG_offset;
      vec2 B_offset=vB_offset;
      
      if (DOT_M_SHADOW_STR == 0.0) {
         // Edge defocus:
         float dist_from_edge = distance_from_edge_linear(coords, EDGE_DEFOCUS_AREA_INV);
         float offset_multiplier = mix(EDGE_DEFOCUS, 1.0, dist_from_edge);
         R_offset *= offset_multiplier;
         G_offset *= offset_multiplier;
         B_offset *= offset_multiplier;
      }
      
      pixel_offsetted.r=texture(in_texture,coords + R_offset).r;
      pixel_offsetted.g=texture(in_texture,coords + G_offset).g;
      pixel_offsetted.b=texture(in_texture,coords + B_offset).b;
      
      vec3 deconvergence_mode = mix(source_pixel.rgb, pixel_offsetted, OFFSET_STRENGTH);
      vec3 shadow_mode = source_pixel.rgb - max( (source_pixel.rgb - pixel_offsetted), vec3(0.0) ) * DOT_M_SHADOW_STR;
      
      return vec4( mix_step(deconvergence_mode, shadow_mode, vDo_shadow_mode),
                   source_pixel.a );
}

#define SIDE_RIGHT 1
#define SIDE_LEFT -1

vec3 pixel_bleed(vec4 pixel_in, vec2 co, sampler2D in_texture, float sourcesize_z) {
   float size = SAT_BLEED_SIZE;
   #ifdef D3D_WORKAROUND
      // d3d11 compiler complains it is unable to unroll the loop because it is
      // clueless about the maximum pragma value; d3d12 hangs somewhere.
      size = min(5.0,SAT_BLEED_SIZE) ;
   #else 
      size = min(20.0,SAT_BLEED_SIZE) ;
   #endif
   

   //apply strength modifier to blur ntsc artifacts more.
   float strength_modifier = 1.0;
   float w = SAT_BLEED_STRENGTH;
   
   //the following should or not be conditional to using ntsc color bleeding?
      strength_modifier = mix(1.0, pixel_in.a, DO_NTSC_ARTIFACTS);
      w = SAT_BLEED_STRENGTH * clamp (strength_modifier, (1-NTSC_ARTF_NOBLEED), 1.0 );
      if (vShow_artifact_mask == 1.0) return vec3(strength_modifier);
   
      
   vec3 blur_YIQ_l = pixel_in.rgb * vmat3_RGB2XXX;    //Work in YIQ space ot YUV space (ntsc, pal)
   vec3 blur_YIQ_r = blur_YIQ_l;
      
   vec2 off_l = vec2(SIDE_LEFT  * sourcesize_z,0.0);
   vec2 off_r = vec2(SIDE_RIGHT * sourcesize_z,0.0);
   
   //Compute chroma diff to drive dot crawl:
   float chroma_now  = dot(blur_YIQ_l.yz, vec2(1.0));
   float chroma_next = dot(vec3(texture(in_texture, co + off_r).rgb * vmat3_RGB2XXX).yz, vec2(1.0));
   float chroma_prev = dot(vec3(texture(in_texture, co + off_l).rgb * vmat3_RGB2XXX).yz, vec2(1.0));
   float chroma_diff_next = abs(chroma_next-chroma_now);
   float chroma_diff_prev = abs(chroma_prev-chroma_now);
   chroma_diff_next *= chroma_diff_next; // soft treshold for dot crawl
   chroma_diff_prev *= chroma_diff_prev; // soft treshold for dot crawl
   
   //Compute dot crawl "carrier"
   float sin_crawl = sin(co.y*params.OriginalSize.y*0.5 *pi-params.FrameCount*0.2);
   sin_crawl*=sin_crawl;
   sin_crawl *= SAT_BLEED_DOTC * 2.0;
   
   float apply_dot_crawl_prev = chroma_diff_prev*sin_crawl;
   float apply_dot_crawl_next = chroma_diff_next*sin_crawl;
   
   for ( float i=1 ; i <= size ; i++ ){
      w=w/SAT_BLEED_FALLOFF;  //w = w * exp(i*i*(1-SAT_BLEED_FALLOFF)*0.1);
      vec3 smp_YIQ = texture(in_texture, co - i*off_l ).rgb * vmat3_RGB2XXX;
      //Blur Y, I and Q
      blur_YIQ_l = mix(blur_YIQ_l.xyz, smp_YIQ.xyz, w/vBandwidths);
      
      smp_YIQ = texture(in_texture, co - i*off_r ).rgb * vmat3_RGB2XXX;
      //Blur Y, I and Q
      blur_YIQ_r = mix(blur_YIQ_r.xyz, smp_YIQ.xyz, w/vBandwidths);
   }
   
   

   blur_YIQ_r.x = mix( blur_YIQ_r.x, (blur_YIQ_r.y + blur_YIQ_r.z)*0.5, apply_dot_crawl_next );
   blur_YIQ_l.x = mix( blur_YIQ_l.x, (blur_YIQ_l.y + blur_YIQ_l.z)*0.5, apply_dot_crawl_prev );
   
   
   //return vec3(apply_dot_crawl);
   
   
   vec3 blur_RGB_l = blur_YIQ_l * vmat3_XXX2RGB; //return to RGB colorspace
   vec3 blur_RGB_r = blur_YIQ_r * vmat3_XXX2RGB; //return to RGB colorspace
   
   // Clamping min to 0.0 is needed for nvidia to avoid bad graphical glitches, why?
   return max(mix(blur_RGB_l,blur_RGB_r,0.5), 0.0);
}


void main() {
   vec4 pixel_out;

   pixel_out = texture(upscale_pass, vTexCoord );
   
   // CVBS bleeding before deconvergence is better when CVBS bleeding is set to pal.
   // That way deconvergence does not completely succumb to PAL bleed.
   // For performance reasons, is still a tradeoff, but at least you can modulate
   // between the two.
   
   //bleed
   if (DO_SAT_BLEED > 0.0)
      pixel_out.rgb = pixel_bleed(pixel_out, vTexCoord, upscale_pass, params.OriginalSize.z*0.5);
   
   //... and shift
   if (vDecon_or_JustShadow > 0.0 )
      pixel_out = deconvergence_shadow(vTexCoord, upscale_pass, pixel_out);


   //gamma-in
   pixel_out.rgb = pow(pixel_out.rgb, vec3(IN_GLOW_GAMMA));

   //Alpha carriest ntsc artifacts mask.
   FragColor = pixel_out;
}
