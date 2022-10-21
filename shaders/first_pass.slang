#version 450
#include "config.inc"
#define eps 1e-8

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 r_offset;
layout(location = 2) out vec2 g_offset;
layout(location = 3) out vec2 b_offset;

#include "functions.include.slang"

#define RGB_SHIFT_RANGE 20

void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = TexCoord;
   if (DO_SHIFT_RGB == 1.0) {
      float in_aspect = 1.0;//get_in_aspect();
      float spr_radius = min(params.SourceSize.z, params.SourceSize.w);
      r_offset=offsets_from_float(SHIFT_R+210.0,RGB_SHIFT_RANGE);
      g_offset=offsets_from_float(SHIFT_G+210.0,RGB_SHIFT_RANGE);
      b_offset=offsets_from_float(SHIFT_B+210.0,RGB_SHIFT_RANGE);
   }
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 r_offset;
layout(location = 2) in vec2 g_offset;
layout(location = 3) in vec2 b_offset;
layout(location = 0) out vec4 FragColor;

layout(set = 0, binding = 2) uniform sampler2D Source;

#include "functions.include.slang"

vec3 pixel_flickering(vec3 pixel_cur) {
   vec4 pixel_out;
   float mymod = params.FrameCount % 3;
   
   if (mymod == 0.0) return pixel_cur;
   
   vec3 flickline;
   if (mymod == 1.0 )
      flickline = texture(Source,vTexCoord + vec2(0.0,params.OriginalSize.w/2.0)).rgb;
   else if (mymod == 2.0) 
      flickline = texture(Source,vTexCoord - vec2(0.0,params.OriginalSize.w/2.0)).rgb;

   float lumdiff = (flickline.r+flickline.g+flickline.b)/3.0 -
                   (pixel_cur.r+pixel_cur.g+pixel_cur.b)/3.0;
   
   if (lumdiff > 0.0) {
      lumdiff = scale_to_range(lumdiff,0.2,0.7);
      return mix(pixel_cur,flickline,lumdiff);
   } else {
      return pixel_cur;
   }

}

vec3 pixel_offset(vec3 pixel_cur) {
      vec2 d = -vec2(params.SourceSize.z, params.SourceSize.w)*0.5;
      vec3 pixel_offset;
      pixel_offset.r=texture(Source,vTexCoord + r_offset * d).r;
      pixel_offset.g=texture(Source,vTexCoord + g_offset * d).g;
      pixel_offset.b=texture(Source,vTexCoord + b_offset * d).b;
      return mix(pixel_cur,pixel_offset,OFFSET_STRENGTH);
}


vec3 kelvin2rgb(float k) {
   k = clamp(k,1000,40000);
   k=k/100.0;
   float tmpCalc;
    vec3 pixel_out;
   if (k<=66) {
      pixel_out.r = 255;
      pixel_out.g = 99.4708025861 * log(k) - 161.1195681661;
   } else {
      pixel_out.r = 329.698727446 * pow(k - 60 ,-0.1332047592);   
      pixel_out.g = 288.1221695283 * pow(k-60, -0.0755148492);      
   }
   
   if (k >= 66)
      pixel_out.b = 255;
   else if (k<=19) 
      pixel_out.b = 0;
   else
      pixel_out.b = 138.5177312231 * log(k - 10) - 305.0447927307;
   
   return pixel_out/255.0;
}

void main() { 

   vec4 pixel_out = texture(Source,vTexCoord);
   
   if (DO_SHIFT_RGB == 1.0) pixel_out = vec4(pixel_offset(pixel_out.rgb), 1.0);

   
   
    if (DO_CCORRECTION == 1.0) {
        //Saturation modifier
        if (!(SATURATION == 1.0)) {
         //pixel_out *=vec4(pixel_out.rgb,1.0);
         const vec3 W = vec3(0.2125, 0.7154, 0.0721);
         vec3 intensity = vec3(dot(pixel_out.rgb, W));
         pixel_out.rgb = mix(intensity, pixel_out.rgb, SATURATION);
         //pixel_out = pow(pixel_out,vec4(0.5));  
         //float l = length(pixel_out.rgb);
         //pixel_out =  vec4(normalize( pow(pixel_out.rgb + vec3(eps), vec3(SATURATION)))*l,1.0)  ;
        }
        
        if (CONTRAST != 0.0 || BRIGHTNESS != 0.0)
            pixel_out.rgb = scale_to_range_vec3(pixel_out.rgb, -CONTRAST, 1+CONTRAST) + BRIGHTNESS;
       
       if (TEMPERATURE != 6500.0)
            pixel_out.rgb = pixel_out.rgb*kelvin2rgb(TEMPERATURE);

    }
   
   if (DO_SCANLINES == 1.0) {
      if (scanline_have_to_flicker(is_interlaced())) pixel_out.rgb = pixel_flickering(pixel_out.rgb);
   }
   
   FragColor = pixel_out;
   
   //Use one of the following to debug:
      //FragColor=vec4(abs(sin(params.FrameCount/3.14/4))); //white fade
      //FragColor=vec4(abs(sin(params.FrameCount/3.14/20)),0.0,0.0,0.0); //red fade
      //FragColor=vec4(1.0);
      //FragColor=vec4(0.38,0.0,1.0,1.0);
      //FragColor=vec4(0.38,0.0,1.0,1.0)*vTexCoord.x;
      //FragColor=vec4(vTexCoord.x); //H bw gradient
      //FragColor=vec4(floor(vTexCoord.x*16)/16); //H bw gradient 16gray
      //FragColor=vec4(floor(vTexCoord.x*64)/64); //H bw gradient 64gray
      //if  (mod(params.FrameCount,100) < 50) FragColor=vec4(0.0) ; else FragColor=vec4(1.0);      
}
 
  
