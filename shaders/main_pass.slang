#version 450
#include "config.inc"


#define eps 1e-8
#define pi 3.141592654


// RGB mask:       R     G     B
 #define m1 vec3 ( 1.0 , 0.0 , 0.0 )    //col 1
 #define m2 vec3 ( 0.0 , 1.0 , 0.0 )    //col 2
 #define m3 vec3 ( 0.0 , 0.0 , 1.0  )   //col 3

// Blur sizes must not depend on input resolution
#define scalemod_x (global.in_glow_and_scanline_flickering_passSize.x/360.0)
#define scalemod_y (global.in_glow_and_scanline_flickering_passSize.y/270.0)


#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;


#include "functions.include.slang"
void main() {
   gl_Position = global.MVP * Position;
   vTexCoord = get_scaled_coords(TexCoord,global.FinalViewportSize, is_rotated());
   vOutputCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D Original;
layout(set = 0, binding = 3) uniform sampler2D FXAA_pass;
layout(set = 0, binding = 4) uniform sampler2D in_glow_and_scanline_flickering_pass;
layout(set = 0, binding = 5) uniform sampler2D halo_pass;
layout(set = 0, binding = 6) uniform sampler2D first_pass;



// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "pixel_glows.include.slang"    
#include "functions.include.slang"
vec3 pixel_vmask(vec3 source, vec3 lm1,vec3 lm2,vec3 lm3,
                 vec3 white_reference, float over_white,bool is_scanlined) {
    int col = int( vOutputCoord.x * params.OutputSize.x );
    vec3 pixel_out;
    vec3 vmasked;
    if (mod(col, 3) < 1) vmasked = lm1*source;
    else if (mod(col, 3) < 2) vmasked = lm2*source;
    else vmasked = lm3*source;

    if (over_white == 1.0) pixel_out = vmasked;
        else {
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
    float col_2 =  vOutputCoord.x * params.OutputSize.x;
    float line_2 = vOutputCoord.y * params.OutputSize.y;

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
            return vec3(0.0,0.0,0.0) ; 
        }
    } else {
        if  (int(mod(line,2.0  )) == 0) {
            return vec3(0.0,0.0,0.0) ; 
        }
    }
    return pixel_out;
}

/* freq = 0.500000
   omega = pi x 2 * freq --> omega = pi x 2 x 0.5 = pi. (is the Angular frequency)
*/
#define omega 3.14159265358979
#define ps_lines_white 1.0000

vec3 pixel_scanline_static(vec3 color, vec2 coords) {
   /* Code modified from scanlines-sine-abs.glsl by RiskyJumps
      license: public domain
   */
    int period = (params.OriginalSize.y > MIN_LINES_INTERLACED ) ? 2 : 1 ;
    float angle = coords.y * omega * period * params.OriginalSize.y ;
    float lines = abs(sin(angle));
  
    lines = (lines*lines);
  
    if (SCANLINE_DARK >= 0.0) {
        lines = lines * (ps_lines_white - SCANLINE_DARK) + SCANLINE_DARK;
    } else {        
        float deepness = -SCANLINE_DARK;
        lines = lines * ((1-SCANLINE_DARK) ) + SCANLINE_DARK ;
    }

    color *= min(lines,1.0); // <-- not clamping here may produce scanline dephasing.
    
    return color;
}

vec4 main_wrap(vec2 co) {
    bool isinterlaced = is_interlaced();
    bool flickering_scanlines = (DO_SCANLINES == 1.0) && scanline_have_to_flicker(isinterlaced) ;


    vec3 pixel_in;
    vec3 pixel_glowed;
    vec3 pixel_scanlined;
    
    //Get the first available pixel_in:
    if  ((DO_IN_GLOW == 1.0) || flickering_scanlines) {
            pixel_in = texture(in_glow_and_scanline_flickering_pass,co).rgb;
            pixel_glowed = pixel_in;
            pixel_scanlined = pixel_in;
        }
            else if (DO_FXAA == 1.0) 
        pixel_in = texture(FXAA_pass,co).rgb ;
            else
        pixel_in = texture(first_pass,co).rgb ;
        
    vec3 pixel_out = pixel_in;


    // Non flickering scanlines
    if ( DO_SCANLINES == 1.0 )  {
        if  (!flickering_scanlines) {  //flickering scanlines are handled in previous pass
            if  (! ( isinterlaced  && (scanline_disable_on_interlace == 1.0))  ) {
                pixel_scanlined = pixel_scanline_static(pixel_out,co);
                pixel_scanlined = min(vec3(1.0),pixel_scanlined);
                pixel_out = min(vec3(1.0),pixel_out);
            }
            //Mix scanline and glow pixel; depending on whiteness.
            if (DO_IN_GLOW == 1) {
                float in_luminance = (pixel_glowed.r+pixel_glowed.g+pixel_glowed.b)/3;
                //in_luminance *=in_luminance;
                //float in_luminance = max(max(pixel_glowed.r,pixel_glowed.g),pixel_glowed.b);
                in_luminance = min(in_luminance  * GLOW_OVER_DARK_SCANLINES, 1.0) ;
                pixel_out = mix(pixel_scanlined,pixel_glowed,in_luminance) ;
                } else {
                pixel_out = pixel_scanlined;
            }   
        }
    }     
    
    //Vertical RGB Mask
    if (DO_RGB_MASK == 1.0 ) {
        vec3 m1f = m1 + 1.0 - RGB_MASK_STRENGTH ;
        vec3 m2f = m2 + 1.0 - RGB_MASK_STRENGTH ;
        vec3 m3f = m3 + 1.0 - RGB_MASK_STRENGTH ;
        m1f = min(vec3(1.0),m1f) ;
        m2f = min(vec3(1.0),m2f) ;
        m3f = min(vec3(1.0),m3f) ;
        pixel_out = pixel_vmask(pixel_out,m1f,m2f,m3f,pixel_in,VMASK_OVERWHITE,(DO_SCANLINES == 1));
    }

    //Horizontal screen lines
    if (DO_DARKLINES == 1.0 ) {
        float MYDARKLINES_TRANSPARENCY = 1.0 - DARKLINES_STRENGTH;
        pixel_out = pixel_darklines(pixel_out,DARKLINES_PERIOD,MYDARKLINES_TRANSPARENCY,DO_DARKLINES_VOFFSET,pixel_in,DRKLN_OVERWHITE);
    }

    //Halo
    if (DO_HALO == 1.0 ) {
        vec3 pixel_haloed = texture(halo_pass,co).rgb;
        pixel_out += pixel_haloed;
    }

    
    if (DO_CCORRECTION == 1.0) {
        //Gamma correction
        vec3 cc = vec3(1.0);
        if  (GAMMA_OUT != 1.0) {
            cc=vec3(GAMMA_OUT);
            pixel_out = pow(pixel_out,cc);
        }
    }

    //Saturation modifier
    if (!(saturation == 1.0)) {
        float l = length(pixel_out);
        pixel_out =  normalize( pow(pixel_out.rgb + vec3(eps), vec3(saturation)))*l  ;
    }

    
    //Out
    return vec4(pixel_out,1.0) ; //* border(border_coords);
}

void main() {
    vec2 coords = vTexCoord;
    vec2 coords_curved = vTexCoord;
    //Curvature: set coords_curved coordinate: (global var)
        if (DO_CURVATURE == 1.0) {
            if ((GEOM_WARP_X > 0.0) || (GEOM_WARP_Y > 0.0))
                coords_curved = Warp(coords_curved,GEOM_WARP_X,GEOM_WARP_Y);
        }
        
        if (DO_BEZEL == 1.0) {
            coords_curved = zoomout_coords(coords_curved, -BEZEL_INNER_ZOOM , 1.0);
            coords = zoomout_coords(coords, -BEZEL_INNER_ZOOM , 1.0);
        }
    
   //FIXME: bezel may need a wider border when zoomed in.
            //But for performance reasons we can wide the border in relation to the desidered reflection area.
            //by now, just wide it to the screen content.

    bool is_border = false;
    
    if (border_needed()) {
        float WIDEN = 0.0;
        if (DO_BEZEL == 1.0) WIDEN = BEZEL_REF_END - BEZEL_REF_START;
   
        bool b_is_rotated = is_rotated();
        bool is_outside_x = ((coords.x > 1.0+WIDEN ) || (coords.x < 0.0 - WIDEN) );
        bool is_outside_y = ((coords.y > 1.0+WIDEN ) || (coords.y < 0.0 - WIDEN) );
        is_border = (b_is_rotated && is_outside_y) || (!b_is_rotated && is_outside_x);

   }
   
   if (is_border)
       FragColor = mark_outer_frame(vec3(0.0));
   else
       FragColor = main_wrap(coords_curved);
}


