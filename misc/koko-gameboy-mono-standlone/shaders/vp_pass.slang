#version 450

#include "config.inc"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;


layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;
layout(location = 2) out vec2 spot_offset;
layout(location = 12) out float vIn_aspect;
layout(location = 18) out vec3 vDotMat_Grid_Color;

#include "includes/functions.include.slang"

void main() {
    gl_Position = global.MVP * Position;
    vIn_aspect = get_in_aspect();
    
    //Calculate vTexcoord as fractional or integer scaled?
        if ( need_NO_integer_scale() )
            vTexCoord = get_scaled_coords_aspect(TexCoord,global.FinalViewportSize, vIn_aspect, false) + vec2(0.0000);
                else
            vTexCoord = integer_scale(TexCoord, vIn_aspect, false, GAME_GEOM_INT_SCALE-1.0 ) + vec2(0.0001); //<- without the offset, SCANLINE_MIN doesn't work.


    vOutputCoord = TexCoord;

    //SPOT
        spot_offset = offsets_from_float(S_POSITION+420.0,40);
        spot_offset = spot_offset / 10.0 + vec2(0.0,1.0);

    //Calc dotmat grid color
        vDotMat_Grid_Color = vec3(DOT_M_G_BRT);

        vDotMat_Grid_Color = color_tools(vec3(DOT_M_G_BRT), kelvin2rgb(TEMPERATURE));
        //Since we modify grid brightness via a specific use parameter, explicitely multiply it by that:
            vDotMat_Grid_Color *= DOT_M_G_BRT ;

}


#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 2) in vec2 spot_offset;
layout(location = 12) in float vIn_aspect;
layout(location = 18) in vec3 vDotMat_Grid_Color;

layout(location = 0) out vec4 FragColor;


layout(set = 0, binding = 1) uniform sampler2D Source;


#define RECT01 vec4(0.0, 0.0, 1.0, 1.0)


#include "includes/functions.include.slang"



vec4 fn_pixel_dotmat(vec2 coords, vec3 pixel_in) {
  
       
    //Base angle, depends on original size:
        vec2 angle_base = coords * pi * params.OriginalSize.xy; //FIXME here we want .yy to make integer scaling

    //Zoom to debug:
        angle_base/=DOT_M_MULTIPLY;

    //Set the rgb and grid sharpness:
        vec3 s_rgb = vec3(DOT_M_RGB_SHARP);
        float s_grid = DOT_M_G_SHARP;
        
    //Generate bw grid:     
        vec2 grid = cos(angle_base);
        grid = grid * grid;
        grid = pow(grid, vec2(s_grid));
        grid = 1 - grid;

    //Generate rgb mask 
    vec3 mask_rgb=vec3(1.0);
    if (DOT_M_RGB_STR > 0.0) {
        //float wideness_k = DOT_M_RGB_WID;
        float rgb_wideness = (pi/4.0); // * wideness_k;
        
        //Generates 3 sines with 1/3 pi offset
            vec3 angle_rgb = vec3( angle_base.x + rgb_wideness,
                                   angle_base.x - pi,
                                   angle_base.x - rgb_wideness );
        
            mask_rgb = sin(angle_rgb);
            mask_rgb *= mask_rgb;
            mask_rgb = pow(mask_rgb, s_rgb);
            
        //Adjust green gain
            mask_rgb.g *= DOT_M_G_GAIN;
            
        //Apply strength
            mask_rgb=mix(vec3(1.0), mask_rgb, DOT_M_RGB_STR);
    }
    

    //Combine gridx and gridy into a single one
        //float fgrid = min(grid.x, grid.y);
        float fgrid = grid.x* grid.y;

    //Modify strength for "paint on background" option

        //Smoothly fadeout grid on background
            //The fadeout size:
                float fade_size = 0.3;
            
            //We invert the smooth logic if threshold is negative. this allow to fadeout
            //the grid on bright or dark backgrounds.
                float lum_scaled = dot(pixel_in, vec3(0.33333));
                lum_scaled = clamp(lum_scaled, 0.0, 1.0);
                lum_scaled = mix_step(1-lum_scaled, lum_scaled, float(DOT_M_G_TRESH > 0.0));
                
            float smooth_threshold = abs(DOT_M_G_TRESH);
            vec2 smooth_range  = vec2(smooth_threshold, smooth_threshold+fade_size);
            float grid_smoothstep = 1- smoothstep(smooth_range.x, smooth_range.y, lum_scaled);    


            
    //Adapt grid strength
        float grid_str = DOT_M_G_STR * grid_smoothstep;    
    //Apply strength modifier
        float fgrid_adpt = mix(1.0, fgrid, grid_str);
    

    //Output is the mix of the gap and the rgb masked pixel in.
    //In the alpha channel we put the grid because it could be selectiveli brightened by halo
    return vec4( 
                 mix(vDotMat_Grid_Color, pixel_in * mask_rgb ,fgrid_adpt),
                 fgrid_adpt
               );

}

vec3 fn_pixel_content(vec2 coords) {
    vec3 pixel_out = texture(Source, coords).rgb;

    pixel_out = pow(pixel_out, vec3(GAMMA_IN));

    float scanline_or_dot_mat = 1.0; //init dot grid or scanline mask to 1.0
    
    //Dot mask
        vec4 pixel_grid_mask = fn_pixel_dotmat(coords, pixel_out);
        //grid mask only is needed by halo to selectively light the grid.
            scanline_or_dot_mat = pixel_grid_mask.a;
        //rgb channel goes to pixel_out
            pixel_out = pixel_grid_mask.rgb;

    //Apply gamma out:
        pixel_out = pow(pixel_out, vec3(GAMMA_OUT));


    //Calc a random noise if we need debanding
    float global_noise_static;
        if (DO_SPOT > 0.0) {
            global_noise_static = random_fast(NOISEPOWER, vTexCoord);
        }

    //Vignette
        if (DO_VIGNETTE == 1.0) {
            float dist = length(vec2((coords.x-0.5)*vIn_aspect, coords.y-0.5));
            float vignette = smoothstep(V_SIZE,0.0,dist)*V_POWER;
            pixel_out = pixel_out * vignette + global_noise_static;
        }
        
    //Spot
        if (DO_SPOT == 1.0) {
                float dist = length(vec2((coords.x-0.5)*vIn_aspect, coords.y-0.5)+spot_offset);
                float spot = smoothstep(S_SIZE,0.0,dist)*S_POWER;
                pixel_out = pixel_out + spot + (global_noise_static * (1 - DO_VIGNETTE));
        }
    

        
    return pixel_out;
}



void main() {
    vec3 pixel_out = vec3(0.0);

    //Initial content coords
        vec2 co_content = vTexCoord;

    if (is_first_inside_rect(co_content, RECT01))
        pixel_out = fn_pixel_content(co_content);

    FragColor = vec4(pixel_out, 1.0);

}

