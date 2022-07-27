#version 450
#include "config.inc"
#define eps 1e-8
#define pi 3.141592654

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


// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "pixel_glows.slang"    
    
vec3 pixel_vmask(vec3 source, vec3 lm1,vec3 lm2,vec3 lm3,
                 vec3 white_reference, float over_white,bool is_scanlined) {
    int col = int( vTexCoord.x * params.OutputSize.x );
    vec3 pixel_out;
    vec3 vmasked;
    if (mod(col, 3) < 1) {
        vmasked = lm1*source;
    }
    else if (mod(col, 3) < 2) {
        vmasked = lm2*source;
    }
    else {
        vmasked = lm3*source;
    }
    if (over_white == 1.0) {
        pixel_out = vmasked;
    } else {
        float whiteness=(white_reference.r+white_reference.g+white_reference.b)/3.0;
        whiteness-= over_white;
        whiteness=  clamp(whiteness,0.0,1.0);
        pixel_out=  mix(vmasked,source,whiteness);
    }
    
   return pixel_out;

}

//(3 pixels unless changing m1,m2,m3 datatype)
#define Darkline_part_w 3 
#define Darkline_part_w_x2 6
vec3 pixel_darklines(vec3 source,float darkline_every, float darkline_trans,
                     float do_offset, vec3 white_reference,float over_white) {

    //vec3 pixel_out=source;
    float col_2 =  vTexCoord.x * params.OutputSize.x;
    float line_2 = vTexCoord.y * params.OutputSize.y;

    if (over_white != 1.0) {
        //less effect on bright colors.
        float whiteness=(white_reference.r+white_reference.g+white_reference.b)/3.0;
        darkline_trans+=(whiteness-over_white);
        darkline_trans=clamp(darkline_trans,0.0,1.0);
    }

    if (do_offset == 1.0) {
        int hmask_shape_offset = int (darkline_every/2.0) + 1 ;
        if  (int(mod(line_2, darkline_every)) == 1) {
            if (int(mod(col_2, Darkline_part_w_x2)) < Darkline_part_w) {
                return source * darkline_trans;
            }
        } else if  (int(mod(line_2, darkline_every)) == hmask_shape_offset ) {
            // DRAW WITH OFFSET:
            col_2+=Darkline_part_w;
            if ((int(mod(col_2, Darkline_part_w_x2))) < Darkline_part_w) {
                return source * darkline_trans;
            }
        }
    } else {

        if ( darkline_every >= 0.0) {
            if  (int(mod(line_2, darkline_every)) == 1) {
                return source * darkline_trans;
            }
        }

        if ( darkline_every < 0.0) {
            if  (int(mod(line_2, abs(darkline_every) )) != 1) {
                return source * darkline_trans;
            }
        }
    }

    return source;
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

#define ps_freq 0.500000
#define ps_lines_white 1.0000
vec3 pixel_scanline(vec3 color, int inversion) {
   /* Code modified from scanlines-sine-abs.glsl by RiskyJumps
      license: public domain
   */
    float freq  =           0.500000 ;
    float lines_black = SCANLINE_DARK;
    float omega = 2.0 * pi * ps_freq; // Angular frequency
    float angle = vTexCoord.y * omega * params.OriginalSize.y;
    float lines;
    
    if (inversion == 1) {
        lines = sin(angle);
    } else {
        lines = cos(angle);
    }
    lines = abs(lines);
    
    /* //Modulate the blackness via the input color so that scanlines disappear on bright ones?
        float in_luminance = (color.r+color.g+color.b) /4.5; // <<-- FIXME: may need to tune this 
        float in_luminance = max(max(color.r,color.g),color.b)/1;
        float in_luminance = (color.r + color.g + color.b)/3;
        float in_luminance = 0.0;
        lines_black = max(lines_black,in_luminance);
    */
    lines *= ps_lines_white - lines_black;
    lines += lines_black;
    lines= (lines*lines);
    //lines= (lines*lines);
    //lines= (lines*lines); 
    color *= min(lines,1.0); // <-- not clamping here may produce scanline dephasing.
    return color;
}

vec3 pixel_scanline_and_flicker(vec3 color) {
    //Is interlaced?
    int is_interlaced=0;
    if (params.OriginalSize.y > 300) {
        is_interlaced=1;
    }

    //Skip scanlines on interlaced content?
    if ((is_interlaced == 1) && (scanline_disable_on_interlace == 1)) { return color; }
   
    //Do flickering based on user prefs?
    //(blank odd lines on odd frames and even lines on even frames)
    if ((scanline_flickering == 1.0) || ((scanline_flickering==2.0) && (is_interlaced == 1))) {
        if  (int(mod(float(params.FrameCount),2  )) <  1.0 ) {
            return  pixel_scanline(color, 0);
        } else {
            return  pixel_scanline(color, 1);
        }
    }
    //Do simple scanlines:
    return pixel_scanline(color,0);
}


void main(void) {
    vec3 pixel_in = texture(Source, vTexCoord).rgb;
    vec3 pixel_out = pixel_in;
    vec3 pixel_haloed = pixel_in;
    vec3 pixel_glowed = pixel_in;

    // Scanlines, interlacing, flickering
    if ( DO_SCANLINES == 1.0 ) {
        vec3 pixel_scanlined = pixel_scanline_and_flicker(pixel_in);
        pixel_out = pixel_scanlined.rgb;
        pixel_out = min(vec3(1.0),pixel_out);
    }     
    
    /* Input signal is blurred and glows.
       glow power versus blur power is defined by IN_GLOW_ADD.
       this allows the rgb vmask to light up on the black scanline.
     */
    if (DO_IN_GLOW == 1) {
        vec3 pixel_glowed = pixel_glow(Source, in_glow_wh,in_glow_wh,in_glow_power,in_glow_gamma,params.SourceSize).rgb;
        //glowed = min(glowed,1.0); //Input signal glow dont have "to white" the phosphors. //FIXME: In dubt to turn it on; previous glsl version did not have this.
        if (IN_GLOW_ADD>0.0) {
            pixel_glowed =mix(pixel_out,pixel_out+pixel_out,IN_GLOW_ADD);
        }
        //Mix scanline and glow pixel; depending on whiteness.
        if (DO_SCANLINES == 1) {
            float in_luminance = (pixel_glowed.r+pixel_glowed.g+pixel_glowed.b)/3;
            pixel_out = mix(pixel_out,pixel_glowed,in_luminance) ;
            } else {
            pixel_out = pixel_glowed;
        }
        pixel_out = min(vec3(1.0),pixel_out);
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
    if (DO_HALO == 1.0 ) {
        pixel_haloed = pixel_glow(Source, halo_w,halo_h,halo_power,halo_gamma, params.SourceSize).rgb;
        pixel_out += pixel_haloed;
    }

    if (DO_CCORRECTION == 1.0) {
        //Gamma correction
            vec3 cc = vec3(1.0);
            if  (GAMMA_OUT != 1.0) {
                    cc=vec3(GAMMA_OUT);
            }
            pixel_out = pow(pixel_out,cc);

        //Saturation modifier
        if (!(saturation == 1.0)) {
            float l = length(pixel_out);
            pixel_out =  normalize( pow(pixel_out.rgb + vec3(eps), vec3(saturation)))*l  ;
        }
    }
    

    //Out
    FragColor = vec4(pixel_out,0.0);
}
