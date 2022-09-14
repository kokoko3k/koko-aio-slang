#version 450
#include "config.inc"
#define eps 1e-8

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;

#include "functions.include"
void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = get_scaled_coords(TexCoord,params.OutputSize);
    vOutputCoord = TexCoord;
}

// 
#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D main_pass;
layout(set = 0, binding = 3) uniform sampler2D bloom_pass_final;
layout(set = 0, binding = 4) uniform sampler2D vignette_and_spot_pass;
layout(set = 0, binding = 5) uniform sampler2D ambi_temporal_pass;
layout(set = 0, binding = 6) uniform sampler2D ambi_avglum_pass;
layout(set = 0, binding = 7) uniform sampler2D monitor_body;
layout(set = 0, binding = 8) uniform sampler2D reflected_blurred_pass2;

#include "functions.include"

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

vec2 coords = vTexCoord ; //FIXME how bad is this global variable?
//bezel not reflective size in percent of the game size
#define BEZEL_OUT_PERCENT 0.02
#define rxmin (BEZEL_OUT_PERCENT)
#define rxmax (1-BEZEL_OUT_PERCENT)
#define rymin (BEZEL_OUT_PERCENT)
#define rymax (1-BEZEL_OUT_PERCENT)

bool is_reflection_area() {
    return ((vTexCoord.x > rxmin) && (vTexCoord.x < rxmax) && (vTexCoord.y > rymin) && (vTexCoord.y < rymax )) &&
           ((coords.x < 0.0 ) || (coords.x > 1.0) || (coords.y < 0.0) || (coords.y > 1.0));
}


float quad_smoothstep(vec2 co, float smooth_threshold) {
    float mysmoothstep =              smoothstep(-smooth_threshold,smooth_threshold, co.x);
    mysmoothstep = min( mysmoothstep, smoothstep(-smooth_threshold,smooth_threshold, co.y) );
    mysmoothstep = min( mysmoothstep, smoothstep(1+smooth_threshold,1-smooth_threshold, co.y) );
    mysmoothstep = min( mysmoothstep, smoothstep(1+smooth_threshold,1-smooth_threshold, co.x) );
    return mysmoothstep;
}

vec3 compose_bezel_over(vec3 full_viewport) {
    //No need to draw anything outside this:
    if (vTexCoord.x < 0  || vTexCoord.y < 0 || vTexCoord.x > 1.0 || vTexCoord.y > 1.0) return full_viewport;

    vec3 bezel_out;
    
    //Main lut:
    vec4 bezel = texture(monitor_body,vTexCoord);
    
    //We use the red component of the bezel to express its luminance (define bezel_luminance bezel.r)
    vec3 bezel_colored = bezel_color(bezel_luminance);

    //This is the reflection to be composed over the bezel);
    vec3 pixel_mirrored = texture(reflected_blurred_pass2,
                          vOutputCoord + displace( (global.FinalViewportSize.z+global.FinalViewportSize.w)*0.5 ) ).rgb;
       
    //(Optionally) draw a black border around the picture //FIXME: make me optional
    vec3 full_viewport_antialiased = full_viewport;
    float border_size = 0.03;
    if ( coords.x + border_size > 0.0 && coords.y + border_size > 0.0 && 
         coords.x - border_size < 1.0 && coords.y -border_size < 1.0  &&
         coords.x > -border_size ) {
        float smooth_threshold_antialias = (params.OutputSize.z + params.OutputSize.w) * 2.0;
        full_viewport_antialiased *= quad_smoothstep(coords,smooth_threshold_antialias) ;
    }
    
    
    //Generate the reflection area and mix it over the bezel:
    float smooth_threshold_reflection = (params.OutputSize.z + params.OutputSize.w) * 40.0; //FIXME: it should depend on bezel size, not output size
    float mysmootstep_reflection = quad_smoothstep(coords,smooth_threshold_reflection);
    bezel_out = mix(bezel_colored,pixel_mirrored,mysmootstep_reflection);   //FIXME: solo se la luce è più forte della superficie

        //We use the green component to express Hardness/Specularity; there the reflection will be completely diffused:
        float lut_hardness = bezel.g;
        vec4 pixel_avglum = texture(ambi_avglum_pass,vOutputCoord);
        bezel_out = bezel_out + ( vec3(pixel_avglum.r+pixel_avglum.g+pixel_avglum.b)/3.0   * lut_hardness/10.0);
         
   
    return mix(full_viewport_antialiased, bezel_out, bezel.a);
}


vec4 pixel_inner_frame() {
    vec4 pixel_in = texture(main_pass, vOutputCoord);
    vec3 pixel_out = pixel_in.rgb;
    vec3 bloomed;

    //Curvature
    //vec2 coords = vTexCoord ;
    float l_GEOM_BORDER_WX = GEOM_BORDER_WX;
    float l_GEOM_BORDER_WY = GEOM_BORDER_WY;
    float fborder = 1.0;
    
    if (DO_CURVATURE == 1.0) {
        float geom_gap_size_adj = GEOM_GAP_SIZE;
        if (GEOM_GAP_SIZE < 0.0) geom_gap_size_adj = GEOM_ZOOMOUT;

        if ((GEOM_WARP_X > 0.0) || (GEOM_WARP_Y > 0.0))
            coords = Warp(coords,GEOM_WARP_X,GEOM_WARP_Y);

        vec2 border_coords = vTexCoord;
        if (GEOM_BORDER_WX < 0.0) l_GEOM_BORDER_WX = GEOM_WARP_X;
        if (GEOM_BORDER_WY < 0.0) l_GEOM_BORDER_WY = GEOM_WARP_Y;
        
        if ((l_GEOM_BORDER_WX > 0.0) || (l_GEOM_BORDER_WY > 0.0))
            border_coords = Warp(vTexCoord,l_GEOM_BORDER_WX,l_GEOM_BORDER_WY);

        if ((GEOM_ZOOMOUT + geom_gap_size_adj) > 0.0) {
            coords = zoomout_coords(coords, GEOM_ZOOMOUT, 1.0);
            border_coords = zoomout_coords(border_coords, GEOM_ZOOMOUT-geom_gap_size_adj, 1.0);
        }
        fborder = border(border_coords);
    }
    
    //Mix bloom texture
    if (DO_BLOOM == 1.0 ) {
        bloomed=texture(bloom_pass_final, coords).rgb ;
        if (bloom_bypass == 1.0)
            pixel_out = bloomed;
        else
            pixel_out = pixel_out + (bloomed * BLOOM_MIX );
    }


    //Black frame insertion
    if (DO_ALT_BLANK == 1.0 ) {
        pixel_out = pixel_alternate(pixel_out.rgb, ALT_BLANK_STRENGTH );
    }

 
    bool DO_NOISE = false;
    //vignette
    if (DO_VIGNETTE == 1.0) {
        DO_NOISE = true;
        //float vignette = gauss_xy(0.0, 0.0, v_size, v_power, 0.0, 1.0);
        vec3 vignette = vec3(texture(vignette_and_spot_pass,vTexCoord).r);
        if (v_bypass < 1.0) pixel_out = vignette * pixel_out;
            else
        pixel_out = vignette ;
    }
    
    //Spot 
    if (DO_SPOT == 1.0) {
        DO_NOISE = true;
        //float spot =  gauss_xy(s_center_x, s_center_y, s_size, s_power, 0.0, 10.0);
        vec3 spot = vec3(texture(vignette_and_spot_pass,vTexCoord).g);
        if (s_bypass < 1.0) pixel_out = mix(pixel_out,vec3(1.0), spot);
            else
        pixel_out = vec3(spot) ;
    }

    //Deband
    if (DO_NOISE) pixel_out = pixel_out + random(noisepower); //FIXME: Just use external luts pre-debanded


    //Out
    return vec4(pixel_out,pixel_in.a);
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
    
    FragColor = pixel_out;

    

}
