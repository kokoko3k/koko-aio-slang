#version 450
#include "config.inc"


/*
    CRT Shader by EasyMode
    License: GPL
    
    Modified by kokoko3k, stripped to keep just curvature related code.
*/

#define FIX(c) max(abs(c), 1e-5)
#define PI 3.141592653589
#define TEX2D(c) texture(tex, c)
#define in_texture final_pass
#define in_textureSize final_passSize
//#define in_textureSize SourceSize

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out vec2 vOutputCoord;

#include "functions.include"
void main() {
    gl_Position = global.MVP * Position;
    vTexCoord = get_scaled_coords(TexCoord);
    vOutputCoord = TexCoord;
}

#pragma stage fragment
layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in vec2 vOutputCoord;
layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D in_texture;

float curve_distance(float x, float sharp)
{
    float x_step = step(0.5, x);
    float curve = 0.5 - sqrt(0.25 - (x - x_step) * (x - x_step)) * sign(0.5 - x);

    return mix(x, curve, sharp);
}

mat4x4 get_color_matrix(sampler2D tex, vec2 co, vec2 dx)
{
    return mat4x4(TEX2D(co - dx), TEX2D(co), TEX2D(co + dx), TEX2D(co + 2.0 * dx));
}

vec4 filter_lanczos(vec4 coeffs, mat4x4 color_matrix)
{
    vec4 col = color_matrix * coeffs;
    vec4 sample_min = min(color_matrix[1], color_matrix[2]);
    vec4 sample_max = max(color_matrix[1], color_matrix[2]);

    col = clamp(col, sample_min, sample_max);

    return col;
}

vec2 curve_coordinate(vec2 co, float curvature_x, float curvature_y)
{
    vec2 curve = vec2(curvature_x, curvature_y);
    vec2 co2 = co + co * curve - curve / 2.0;
    vec2 co_weight = vec2(co.y, co.x) * 2.0 - 1.0;

    co = mix(co, co2, co_weight * co_weight);

    return co;
}

float get_corner_weight(vec2 co, vec2 corner, float smoothfunc)
{
    float corner_weight;
    
    co = min(co, vec2(1.0) - co) * vec2(1.0, 0.75);
    co = (corner - min(co, corner));
    corner_weight = clamp((corner.x - sqrt(dot(co, co))) * smoothfunc, 0.0, 1.0);
    corner_weight = mix(1.0, corner_weight, ceil(corner.x));
    
    return corner_weight;
}


vec3 do_curvature(){
    vec2 tex_size = params.in_textureSize.xy ;
    vec2 midpoint = vec2(0.5, 0.5);

    vec2 co = vOutputCoord * tex_size * params.in_textureSize.zw;
    vec2 co2 = vTexCoord * tex_size * params.in_textureSize.zw;
    vec2 xy = curve_coordinate(co, GEOM_WARP_X,GEOM_WARP_Y  );
    
    vec3 col; 
    float corner_weight = get_corner_weight(curve_coordinate(co2, GEOM_CURVATURE, GEOM_CURVATURE ), vec2(GEOM_CORNER_SIZE), GEOM_CORNER_SMOOTH);

    
    if ( (GEOM_WARP_X > 0) || (GEOM_WARP_Y > 0) ) {
        xy *= params.in_textureSize.xy / tex_size;

        vec2 dx = vec2(1.0 / tex_size.x, 0.0);
        vec2 dy = vec2(0.0, 1.0 / tex_size.y);
        vec2 pix_co = xy * tex_size - midpoint;
        vec2 tex_co = (floor(pix_co) + midpoint) / tex_size;
        vec2 dist = fract(pix_co);
        float curve_x, curve_y;
        vec3 col2, diff;

        curve_x = curve_distance(dist.x, SHARPNESS_H * SHARPNESS_H);
        curve_y = curve_distance(dist.y, SHARPNESS_V * SHARPNESS_V);

        vec4 coeffs_x = PI * vec4(1.0 + curve_x, curve_x, 1.0 - curve_x, 2.0 - curve_x);
        vec4 coeffs_y = PI * vec4(1.0 + curve_y, curve_y, 1.0 - curve_y, 2.0 - curve_y);

        coeffs_x = FIX(coeffs_x);
        coeffs_x = 2.0 * sin(coeffs_x) * sin(coeffs_x / 2.0) / (coeffs_x * coeffs_x);
        coeffs_x /= dot(coeffs_x, vec4(1.0));

        coeffs_y = FIX(coeffs_y);
        coeffs_y = 2.0 * sin(coeffs_y) * sin(coeffs_y / 2.0) / (coeffs_y * coeffs_y);
        coeffs_y /= dot(coeffs_y, vec4(1.0));

        mat4x4 color_matrix;


        color_matrix[0] = filter_lanczos(coeffs_x, get_color_matrix(in_texture, tex_co - dy, dx));
        color_matrix[1] = filter_lanczos(coeffs_x, get_color_matrix(in_texture, tex_co, dx));
        color_matrix[2] = filter_lanczos(coeffs_x, get_color_matrix(in_texture, tex_co + dy, dx));
        color_matrix[3] = filter_lanczos(coeffs_x, get_color_matrix(in_texture, tex_co + 2.0 * dy, dx));

        col = filter_lanczos(coeffs_y, color_matrix).rgb;
            } else {
        col = texture(in_texture, vOutputCoord).rgb;
    }
    
    col *= vec3(corner_weight);
    return col;
}


vec4 main_wrap()
{
    
    if (DO_CURVATURE == 1.0) {
        return vec4(do_curvature(), 1.0);
    } else {
        return texture(in_texture, vOutputCoord);
    }
}

#include "functions.include"
void main() {
    vec4 psample = texture(in_texture, vOutputCoord);
    if (is_outer_frame(psample))
        FragColor = mark_outer_frame(vec3(0.0));
            else
        FragColor = main_wrap();

        
}
