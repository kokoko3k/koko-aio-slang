#version 450
#include "config.inc"
#define eps 1e-8

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;

#include "functions.include.slang"
void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = get_scaled_coords(TexCoord,params.OutputSize);
    vOutputCoord = TexCoord;
}


#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D main_pass;
layout(set = 0, binding = 3) uniform sampler2D bloom_pass_final;
layout(set = 0, binding = 4) uniform sampler2D circular_gradient;
layout(set = 0, binding = 5) uniform sampler2D ambi_temporal_pass;
layout(set = 0, binding = 6) uniform sampler2D avglum_pass;
layout(set = 0, binding = 7) uniform sampler2D monitor_body;
layout(set = 0, binding = 8) uniform sampler2D reflected_blurred_pass2;

#include "functions.include.slang"

float displace(float power) {
    vec2 co = vTexCoord ;
    float a  = 12.9898;
    float b  = 78.233;
    float c  = 43758.5453;
    float dt = dot(co.xy, vec2(a, b));
    float sn = mod(dt,3.14);

    float noise_out = fract(sin(sn) * c) - 0.5;
    noise_out = clamp(noise_out, -power, power);
    return noise_out ; 
}

vec2 pixel_vignette_and_spot(vec2 co){
    float in_aspect = get_in_aspect();
    vec2 sv_coords = vec2(co.x * in_aspect - ((0.5 * in_aspect) - 0.5) ,  co.y);
    float f_random = random(noisepower);
    vec2 pixel_out;

    
    if (DO_VIGNETTE == 1.0) {
        vec2 vignette_coords = zoomout_coords(sv_coords,1-v_size,1.0) + vec2(f_random);
        pixel_out.r = texture(circular_gradient,vignette_coords).r * v_power ;
    }

    if (DO_SPOT == 1.0) {
        vec2 spot_coords = sv_coords + vec2(-s_center_x, -s_center_y);
        spot_coords = zoomout_coords(spot_coords,1-s_size,1.0);
        pixel_out.g = texture(circular_gradient,spot_coords).g * s_power + f_random;
    }

    
    return pixel_out;
}


vec4 pixel_border() {
    vec3 ambi = texture(ambi_temporal_pass, vOutputCoord + random(noisepower) ).rgb;
    float l = length(ambi);
    float sat = 1.25;
    float bright = 1.25;
    ambi =  normalize( pow(ambi.rgb + vec3(eps), vec3(sat)))*l * bright  ;
    ambi*=bright;
    return vec4(ambi,0.0);
}

vec3 ambi_noised() {
    return pixel_border().rgb;
}

vec3 pixel_alternate(vec3 source, float whiteness) {
    float line = vTexCoord.y * params.OutputSize.y;
    vec3 pixel_out = source;
    int l_period_half = int(ALT_BLANK_PERIOD) / 2;
    if  (int(mod(float(params.FrameCount),2.0  )) == 1) {
        if  ((mod(line,ALT_BLANK_PERIOD  )) > l_period_half) pixel_out=mix(source,vec3(0), whiteness) ;
    } else {
        if  ((mod(line,ALT_BLANK_PERIOD )) <= l_period_half) pixel_out=mix(source,vec3(0), whiteness) ;
    }
    return pixel_out;
}


float scale_to_range(float x, float dmin, float dmax) {
    //Scales 0..1 range to a..b range
    return ( (dmax-dmin) * x ) + dmin;
}

#define bezel_luminance bezel.r
vec3 bezel_color(float lum)  {
    vec3 col = vec3(BEZEL_R,BEZEL_G,BEZEL_B) + lum;

    float con_min = -0.5*BEZEL_CON + 0.5;
    float con_max =  0.5*BEZEL_CON + 0.5;
    col.r = scale_to_range(col.r, con_min, con_max); //contrast
    col.g = scale_to_range(col.g, con_min, con_max); //contrast
    col.b = scale_to_range(col.b, con_min, con_max); //contrast
    return clamp(col,0.0,1.0);
   
}

vec2 coords_curved = vTexCoord ; //FIXME how bad is this global variable?


float quad_smoothstep(vec2 co, float smooth_end, float smooth_start) {
    float mysmoothstep = 1.0;
    mysmoothstep =              smoothstep(smooth_start, smooth_end, co.x);
    //return mysmoothstep;
    mysmoothstep = min( mysmoothstep, smoothstep(1.0-smooth_start,1.0-smooth_end , co.x) );
    //return mysmoothstep;
    mysmoothstep = min( mysmoothstep, smoothstep(smooth_start, smooth_end, co.y) );
    //return mysmoothstep;
    mysmoothstep = min( mysmoothstep, smoothstep(1.0-smooth_start  , 1.0-smooth_end, co.y) );
    return mysmoothstep;
}

float borderframe(vec2 co, float thickness) {
    float borderout = border(co);
    float borderin = border(zoom(co,1-thickness));
    return borderout-borderin;
}

vec3 compose_bezel_over(vec3 full_viewport) {

    vec2 coords_for_bezel = vTexCoord;
    vec2 coords_for_mirror = vOutputCoord;
    if (BEZEL_FRAME_ZOOM != 0.0)
        coords_for_bezel = zoomout_coords(vTexCoord,-BEZEL_FRAME_ZOOM,1.0);

    //No need to draw anything outside this:
    if (coords_for_bezel.x < 0  || coords_for_bezel.y < 0 || coords_for_bezel.x > 1.0 || coords_for_bezel.y > 1.0) return full_viewport;

    //Main lut:
    vec4 bezel = texture(monitor_body,coords_for_bezel);

    //We use the red component of the bezel to express its luminance (define bezel_luminance bezel.r)
    vec3 bezel_colored = bezel_color(bezel_luminance);

    //This is the reflection to be composed over the bezel);
    vec3 pixel_mirrored = texture(reflected_blurred_pass2,
                          coords_for_mirror + displace( (global.FinalViewportSize.z+global.FinalViewportSize.w)*0.5 ) ).rgb;

    //Draw a black border around the frame to allow a bit underscanning
        vec3 full_viewport_bordered = full_viewport;
        float border_size = 0.05;
        float fborderframe = borderframe(zoom(coords_curved,1+border_size),border_size);
        full_viewport_bordered = full_viewport_bordered*(1-fborderframe);

    //Generate the reflection area and mix it over the bezel:    
        float reflection = quad_smoothstep( zoomout_coords(vTexCoord, -BEZEL_FRAME_ZOOM, 1.0) , BEZEL_REF_START,BEZEL_REF_END );

        //Take the reflection modifier from the texture blue component into account; it is/may be used to lower the reflection in the corners.
            reflection = (reflection * 1.4 -  0.4)  * bezel.b ;
            reflection = clamp (reflection, 0.0, 1.0);
        vec3 bezel_out = bezel_colored + (pixel_mirrored *reflection) ;

    //Mix a bit of ambient light over the bezel
        vec4 pixel_avglum = texture(avglum_pass,vOutputCoord);
        bezel_out = bezel_out + (pixel_avglum.rgb * 0.05);


    //We use the green component to express Hardness/Specularity; there the reflection will be completely diffused.
    //For the task, we use a mipmap whit adeguate precision.
        float lut_hardness = bezel.g;
        if (lut_hardness > 0.0) {
            bezel_out = bezel_out + ( vec3(pixel_avglum.a)  * lut_hardness/3.5);
        }
         
    return mix(full_viewport_bordered, bezel_out, bezel.a);
}

vec4 pixel_inner_frame() {
    vec4 pixel_in = texture(main_pass, vOutputCoord);
    vec3 pixel_out = pixel_in.rgb;
    vec3 bloomed;

    //Curvature
    //vec2 coords_curved = vTexCoord ;
    float l_GEOM_BORDER_WX = GEOM_BORDER_WX;
    float l_GEOM_BORDER_WY = GEOM_BORDER_WY;
    

    if (DO_CURVATURE == 1.0) {
        /*float geom_gap_size_adj = GEOM_GAP_SIZE;
        if (GEOM_GAP_SIZE < 0.0) geom_gap_size_adj = GEOM_ZOOMOUT;*/

        if ((GEOM_WARP_X > 0.0) || (GEOM_WARP_Y > 0.0))
            coords_curved = Warp(coords_curved,GEOM_WARP_X,GEOM_WARP_Y);

        vec2 border_coords = vTexCoord;
        if (GEOM_BORDER_WX < 0.0) l_GEOM_BORDER_WX = GEOM_WARP_X;
        if (GEOM_BORDER_WY < 0.0) l_GEOM_BORDER_WY = GEOM_WARP_Y;
        
        if ((l_GEOM_BORDER_WX > 0.0) || (l_GEOM_BORDER_WY > 0.0))
            border_coords = Warp(vTexCoord,l_GEOM_BORDER_WX,l_GEOM_BORDER_WY);
    }
    
    if (DO_BEZEL == 1.0) {
        coords_curved = zoomout_coords(coords_curved, -BEZEL_INNER_ZOOM , 1.0);
    }
    //Mix bloom texture
    if (DO_BLOOM == 1.0 ) {
        bloomed=texture(bloom_pass_final, coords_curved).rgb ;
        if (bloom_bypass == 1.0)
            pixel_out = bloomed;
        else
            pixel_out = pixel_out + (bloomed * BLOOM_MIX );
    }


    //Black frame insertion
    if (DO_ALT_BLANK == 1.0 ) {
        pixel_out = pixel_alternate(pixel_out.rgb, ALT_BLANK_STRENGTH );
    }


    //vignette and spot

    if (DO_VIGNETTE + DO_SPOT >0.0) {
        vec2 vpixel_vignette_and_spot = pixel_vignette_and_spot(coords_curved);

        if (DO_VIGNETTE == 1.0) {
            if (v_bypass < 1.0) pixel_out = vpixel_vignette_and_spot.r * pixel_out;
                else
            pixel_out = vec3(vpixel_vignette_and_spot.r) ;
        }
        
        //Spot 
        if (DO_SPOT == 1.0) {
            //float spot =  gauss_xy(s_center_x, s_center_y, s_size, s_power, 0.0, 10.0);
            //vec3 spot = vec3(texture(vignette_and_spot_pass,vTexCoord).g);
            if (s_bypass < 1.0) pixel_out = mix(pixel_out,vec3(1.0), vpixel_vignette_and_spot.g);
                else
            pixel_out = vec3(vpixel_vignette_and_spot.g) ;
        }
    }


    float border_inner_frame = 1.0;
    if (DO_BEZEL==1.0 || DO_CURVATURE == 1.0)
        border_inner_frame = border(coords_curved);

    float pixel_out_alpha = pixel_in.a * border_inner_frame;
    //Out
    return vec4(pixel_out,pixel_out_alpha) * border_inner_frame;
}


vec4 main_wrap(){
    /* Handle inner border and outer border, not bezel */
    
    //Just do pixel_inner_frame() and exit when there is no need to paint border.
    if (!border_needed()) return pixel_inner_frame();

    //From now on, we need a border.
        bool bIs_outer_frame = ((vTexCoord.x < 0.0) || (vTexCoord.x > 1.0));
        
        //Handle outer frame cases
            //if we want ambilights in the outer frame, draw it and return
            if ((bIs_outer_frame) && (DO_AMBILIGHT == 1))
                return vec4(ambi_noised(),1.0);
            
            //But if it is just outer frame, just make it black.
            if (bIs_outer_frame) return vec4(0.0);

        
        //Handle inner frame cases
            vec4 vPixel_inner_frame = pixel_inner_frame();
            if (DO_AMBILIGHT == 1) {
                //mix ambilight in the inner frame too, as curvature could shrink into the inner frame.
                return vec4(mix(ambi_noised().rgb,vPixel_inner_frame.rgb,min(vPixel_inner_frame.a*1.5,1.0)),vPixel_inner_frame.a);
                
            }

            //Last case, inner border without ambilight:
            return vPixel_inner_frame;
}


void main() {
    //"Just" handle inner and outer frame here:
    vec4 pixel_out = main_wrap();
    
    //Bezel
    if (DO_BEZEL == 1.0) {
        pixel_out = vec4(compose_bezel_over(pixel_out.rgb),1.0);
    }

    FragColor = pixel_out ;
    
    //FragColor = texture(reflected_blurred_pass2, vOutputCoord);
}
