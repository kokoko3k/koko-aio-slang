#version 450
#include "config.inc"


// RGB mask:       R     G     B
 #define m1 vec3 ( 1.0 , 0.0 , 0.0 )    //col 1
 #define m2 vec3 ( 0.0 , 1.0 , 0.0 )    //col 2
 #define m3 vec3 ( 0.0 , 0.0 , 1.0  )   //col 3

// Blur sizes must not depend on input resolution
#define scalemod_x (params.SourceSize.x/360.0)
#define scalemod_y (params.SourceSize.y/270.0)


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
layout(set = 0, binding = 3) uniform sampler2D Original;

#define rubyTexture Source
#define rubyTextureSize params.SourceSize
#define texture2D(a,b) texture(a,b)


// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "pixel_glows.slang"    
    
vec3 fix_scanlines() {
    return pixel_glow(scanline_sharpness*2,scanline_sharpness,1.0,1.0).rgb;
}

vec3 pixel_vmask(vec3 source4, vec3 lm1,vec3 lm2,vec3 lm3,
                 vec3 white_reference, float over_white,bool is_scanlined) {

    float glfragcoord_x = vTexCoord.x * params.OutputSize.x;
    float col = float(int(glfragcoord_x));
    vec3 pixel_out;
    vec3 vmasked;
    vec3 source = source4.rgb;
    if (int(mod(col, 3.0)) < 1) {
        vmasked = lm1*source;
    }
    else if (int(mod(col, 3.0)) < 2) {
        vmasked = lm2*source;
    }
    else {
        vmasked = lm3*source;
    }
    if (over_white == 1.0) {
        pixel_out = vmasked;
    } else {
        float whiteness=(white_reference.r+white_reference.g+white_reference.b)/3.0;
        whiteness-=over_white;
        whiteness=min(whiteness,1.0);
        whiteness=max(whiteness,0.0);
        pixel_out =  mix(vmasked,source,whiteness);
    }
    

   //Unsure if the following logic has some real usefulness.
   //Maybe it is too complicated, comment by now.
   /* if (is_scanlined)  {
        vec4 lookup=texture(Source, vTexCoord);
        return pixel_out;
        //return pixel_out*lookup.a;
         } else {
        return pixel_out;
    }
   */
   return pixel_out;

}

    

vec3 pixel_darklines(vec3 source,float darkline_every, float darkline_trans,
                     float do_offset, vec3 white_reference,float over_white) {

    vec3 pixel_out=source;
    float col_2 =  vTexCoord.x * params.OutputSize.x;
    float line_2 = vTexCoord.y * params.OutputSize.y;

    float fDarkline_part_w=3.0 ;       //Triads width, float type
    float fDarkline_part_w_x2 = 6.0 ;  //Triads width, float type, *2
    int iDarkline_part_w = 3 ;         //Triads width, integer type
                                       //(3 pixels unless changing m1,m2,m3 datatype

    if (over_white != 1.0) {
        //less effect on bright colors.
        float whiteness=(white_reference.r+white_reference.g+white_reference.b)/3.0;
        darkline_trans+=(whiteness-over_white);
        darkline_trans=max(darkline_trans,0.0);
        darkline_trans=min(darkline_trans,1.0);
    }

    if (do_offset == 1.0) {
        int hmask_shape_offset = int (darkline_every/2.0) + 1 ;
        if  (int(mod(line_2, darkline_every)) == 1) {
            if (int(mod(col_2, fDarkline_part_w_x2)) < iDarkline_part_w) {
                pixel_out =  pixel_out * darkline_trans;
            }
        } else if  (int(mod(line_2, darkline_every)) == hmask_shape_offset ) {
            // DRAW WITH OFFSET:
            col_2+=fDarkline_part_w;
            if ((int(mod(col_2, fDarkline_part_w_x2))) < iDarkline_part_w) {
                pixel_out =  pixel_out * darkline_trans;
            }
        }
    } else {

        if ( darkline_every >= 0.0) {
            if  (int(mod(line_2, darkline_every)) == 1) {
                pixel_out =  pixel_out * darkline_trans;
            }
        }

        if ( darkline_every < 0.0) {
            if  (int(mod(line_2, abs(darkline_every)       )) != 1) {
                pixel_out =  pixel_out * darkline_trans;
            }
        }
    }

    return pixel_out;
}
    
    
vec3 pixel_alternate(vec3 source) {
    float line = vTexCoord.y * params.OutputSize.y;
    vec3 pixel_out = source;
    if  (int(mod(float(params.FrameCount),2.0  )) == 1) {
        if  (int(mod(line,2.0  )) == 1) {
            pixel_out=vec3(0.0,0.0,0.0) ; 
        }
    } else {
        if  (int(mod(line,2.0  )) == 0) {
            pixel_out=vec3(0.0,0.0,0.0) ; 
        }
    }
    return pixel_out;
}
    
void main(void) {
    vec3 pixel_in = texture(Source, vTexCoord).rgb;
    vec3 pixel_out = pixel_in;
    vec3 haloed = pixel_in;
    vec3 glowed = pixel_in;

    /* Input signal is blurred and glows.
       glow power versus blur power is defined by IN_GLOW_ADD.
       this allows the rgb vmask to light up on the black scanline.
     */
    if (DO_IN_GLOW == 1) {
        float in_glow_h = in_glow_wh;
        if (DO_SCANLINES == 1.0) {
            in_glow_h = scanline_sharpness ;
         }
        glowed = pixel_glow(in_glow_wh,in_glow_h,in_glow_power,in_glow_gamma).rgb;
        //glowed = min(glowed,1.0); //Input signal glow dont have "to white" the phosphors. //FIXME: In dubt to turn it on; previous glsl version did not have this.
        if (IN_GLOW_ADD>0.0) {
            pixel_out =mix(glowed,glowed+pixel_out,IN_GLOW_ADD);
        } else {
            pixel_out =  glowed;
        }
    } else if  (DO_SCANLINES == 1.0) {
        if (scanline_sharpness < 15.0) {
            pixel_out=fix_scanlines();
        }
    }

    //Vertical RGB Mask
    if (DO_RGB_MASK == 1.0 ) {
        vec3 m1f = m1 + 1.0 - RGB_MASK_STRENGTH ;
        vec3 m2f = m2 + 1.0 - RGB_MASK_STRENGTH ;
        vec3 m3f = m3 + 1.0 - RGB_MASK_STRENGTH ;
        m1f = min(vec3(1.0,1.0,1.0),m1f) ;
        m2f = min(vec3(1.0,1.0,1.0),m2f) ;
        m3f = min(vec3(1.0,1.0,1.0),m3f) ;
        pixel_out = pixel_vmask(pixel_out,m1f,m2f,m3f,pixel_in,VMASK_OVERWHITE,(DO_SCANLINES == 1));
    }

    //Horizontal screen lines
    if (DO_DARKLINES == 1.0 ) {
    float MYDARKLINES_TRANSPARENCY = 1.0 - DARKLINES_STRENGTH;
        pixel_out = pixel_darklines(pixel_out,DARKLINES_PERIOD,MYDARKLINES_TRANSPARENCY,DO_DARKLINES_VOFFSET,pixel_in,DRKLN_OVERWHITE);
    }

    //Halo
    if (halo_power >= 0.0 ) {
        haloed = pixel_glow(halo_w,halo_h,halo_power,halo_gamma).rgb;
        pixel_out +=haloed;
    }

    //Out
    FragColor = vec4(pixel_out,0.0);
}
