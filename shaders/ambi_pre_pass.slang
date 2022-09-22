#version 450
#include "config.inc"
#define eps 1e-5

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
layout(set = 0, binding = 3) uniform sampler2D isrotated_pass;
layout(set = 0, binding = 4) uniform sampler2D ambi_pre_pass1Feedback;

#define SourceTexture Source
#define SourceTextureSize params.SourceSize

// What follows is an ugly optimization with a lot of code copied and pasted repeated multiple times,
// shamlessly hidden into an include:
#include "blooms.include.slang" 

#include "functions.include.slang"



vec3 circle_smooth(vec2 coords, vec2 middle, float radius, float FALLOFF,float POWER, float lod) {
    float distanza=distance(middle,vec2(coords.x,coords.y));
    float circle = (1-smoothstep(radius-FALLOFF,radius+FALLOFF,distanza))*POWER;
    vec3 circle_color = textureLod(Source,middle,lod).rgb * circle;
    //circle_color = vec3(circle);
    return circle_color;
}

#define tol 0.05  //skip tolerance

/*
#define leds_per_strip 8
#define AMBI_FALLOFF 0.7  //As a general rule, AMBI_FALLOFF+AMBI_POWER < 1.0+internalness
#define AMBI_POWER 0.5   
#define internalness 0.07
*/

/*#define leds_per_strip 8
#define AMBI_FALLOFF 0.3
#define AMBI_POWER 1.7
#define internalness 0.07
*/ 

#define leds_per_strip 8
#define internalness 0.07

/*
   To spare gpu cycles, completely skip the pass 
   by the following factor and return instead the previous 
   (temporal) frame. The trick works because the pass is 
   temporal smoothed later on.
   
   The only downside is that the leds will have less reaction time.
   Esample:
   a FRAME_DIVIDER = 3 over a 60hz content will give
   a minimum reaction time of 60/3=20Hz=50msecs.

*/
#define FRAME_DIVIDER 3

void main() {

    bool is_rotated = texture(isrotated_pass,vec2(0.5,0.5)).r > 0.5;
    if (DO_AMBILIGHT != 1.0) return ; 
    

    if ( mod(params.FrameCount,FRAME_DIVIDER) != 0.0) {
        FragColor = texture(ambi_pre_pass1Feedback,vTexCoord);
        return;
    }
    
    //Scalo al rapporto d'aspetto originale.
    vec2 coords = get_scaled_coords(vTexCoord,global.FinalViewportSize,is_rotated);
    if (DO_BEZEL==1.0) coords = zoomout_coords(coords, -BEZEL_INNER_ZOOM , 1.0);
    
    
    FragColor = vec4(0.0);

    
    
    
    
    bool skip_pass = false;
    //Salta coordinate entro il rettangolo "sotto al monitor"
        //Considera le coordinate curve prima:
        vec2 coords_curved = coords; 
        if (DO_CURVATURE == 1.0) {
            if ((GEOM_WARP_X > 0.0) || (GEOM_WARP_Y > 0.0))
                coords_curved = Warp(coords_curved,GEOM_WARP_X,GEOM_WARP_Y);
                skip_pass =    ( (coords_curved.x > 0.0 + tol && coords_curved.x < 1.0 -tol ) && (coords_curved.y > 0.0 +tol && coords_curved.y < 1.0 - tol) );
        }    
    //...e quelle dritte dopo (necessarie anche quando si fa la curvatura, perchè ritorna valori particolari negli angoli.
    skip_pass = skip_pass && !( (coords.x < 0.0 -tol || coords.x > 1.0 +tol) ||  (coords.y < 0.0 -tol || coords.y > 1.0 +tol) );


    if ( skip_pass ) {
        //float lod_debug = log2(params.SourceSize.y / leds_per_strip);
        //FragColor = textureLod(Source,coords,lod_debug);
        return;
    }

    vec3 pixel_out = vec3(0.0);
    float radius=0.001;

    float bordo_min=internalness ;
    float bordo_max=1.0-internalness ;
 
    float passo = (bordo_max - bordo_min)  / (leds_per_strip-1);
    
    //Prendo una texture precisa led_strip x led_strip, ne calcolo il lod:
    float lod = log2(params.SourceSize.y / leds_per_strip);
    
   /* 
    float passi = 1.0;
    float tolleranza_bordo = passo;
    vec3 circle_color = vec3(0.0);
    for (float middle_x=0.0 ; middle_x <=1.0 ; middle_x=middle_x + passo ) {
        for (float middle_y=0.0 ; middle_y <=1.0 ; middle_y=middle_y + passo ) {
            if ((middle_x+tolleranza_bordo > bordo_max) || (middle_y+tolleranza_bordo > bordo_max) ||
               (middle_x-tolleranza_bordo < bordo_min) || (middle_y-tolleranza_bordo < bordo_min)) {
                    vec2 middle=vec2(middle_x,middle_y);
                    float distanza=distance(middle,coords);
                    float circle = (1-smoothstep(radius-AMBI_FALLOFF,radius+AMBI_FALLOFF,distanza))*AMBI_POWER;
                    circle_color = textureLod(Source,middle,lod).rgb * circle;
                    pixel_out += circle_color;
                    //passi+=1;
            }
        }
    }*/
    
   
    
    float middle_x; float middle_y ;
    
    middle_x=bordo_min;
    for (middle_y=bordo_min ; middle_y <= bordo_max+eps ; middle_y=middle_y + passo ) {
        pixel_out +=circle_smooth(coords, vec2(middle_x,middle_y), radius, AMBI_FALLOFF, AMBI_POWER, lod);
    }
    middle_x=bordo_max;
    for (middle_y=bordo_min ; middle_y <=  bordo_max+eps ; middle_y=middle_y + passo ) {
        pixel_out +=circle_smooth(coords, vec2(middle_x,middle_y), radius, AMBI_FALLOFF, AMBI_POWER, lod);
    }    

    middle_y=bordo_min;
    for (middle_x=bordo_min+passo ; middle_x <= bordo_max-passo+eps ; middle_x=middle_x + passo ) {
        pixel_out +=circle_smooth(coords, vec2(middle_x,middle_y), radius, AMBI_FALLOFF, AMBI_POWER, lod);
    }
    middle_y=bordo_max;
    for (middle_x=bordo_min+passo ; middle_x <= bordo_max-passo+eps ; middle_x=middle_x + passo ) {
        pixel_out +=circle_smooth(coords, vec2(middle_x,middle_y), radius, AMBI_FALLOFF, AMBI_POWER, lod);
    }    

    FragColor = vec4(pixel_out,1.0);
    return;


}
