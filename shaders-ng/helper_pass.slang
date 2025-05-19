#version 450

#include "config.inc"

#include "includes/functions.include.slang"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out float vIn_aspect;
layout(location = 2) out vec2 vTexCoord_rotated_maybe;
layout(location = 3) out float vUniformity_return_current; //or feedback


void main() {
	gl_Position = global.MVP * Position;
	vTexCoord = TexCoord;// + 0.0001;
	vIn_aspect = get_in_aspect();
	vTexCoord_rotated_maybe = vTexCoord;
	#ifdef _HAS_ROTATION_UNIFORM
		if (params.Rotation == 1.0) { // 90
			vTexCoord_rotated_maybe.y = 1-vTexCoord_rotated_maybe.y;
		} else
		if (params.Rotation == 2.0){ // 180
			vTexCoord_rotated_maybe = 1-vTexCoord_rotated_maybe;
		} else
		if (params.Rotation == 3.0) { // 270
			vTexCoord_rotated_maybe.x = 1-vTexCoord_rotated_maybe.x;
		}
	#endif

    bool bIs_Interlaced = is_interlaced();

    vUniformity_return_current = float ( (!bdelta_render_enabled()) || 
                                         (!deltarender_preconditions_met(bIs_Interlaced)) || 
                                         (params.FrameCount == 0.0)
								 );
}

#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float vIn_aspect;
layout(location = 2) in vec2 vTexCoord_rotated_maybe;
layout(location = 3) in float vUniformity_return_current; //or feedback



layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D monitor_body_curved;
layout(set = 0, binding = 3) uniform sampler2D helper_passFeedback;
layout(set = 0, binding = 4) uniform sampler2D colortools_and_ntsc_pass;
layout(set = 0, binding = 5) uniform sampler2D colortools_and_ntsc_passFeedback;


float vignette(){
	vec2 sinco = cos((vTexCoord-0.5) / V_SIZE) ;
	return (sinco.y * sinco.x);
}

float screen_uniformity() {

	#define _USPOTSIZE 100
	#define _USPOTSIZE_INV 100/_USPOTSIZE
	#define _USPEED 0.005
	
    vec4  subscale=vec4(5,3,7,4);
    vec2 co = vTexCoord * _USPOTSIZE_INV;
	float t = params.FrameCount*_USPEED;
    float uniformity = sin(co.x * subscale.x + t) * cos(co.y * subscale.y - t);
    uniformity += sin(co.y * subscale.z * sin(t * 0.5)) * cos(co.x * subscale.w + t);
	uniformity *= uniformity;
    uniformity = map_range(uniformity, -1, 1, UNIFORMITY,  (1-UNIFORMITY)/2.5 +1 );
	return uniformity * vignette();
}

bool DR_uniformity_safe_update() {
	//when it is ok to update uniformity when deltarender is enabled
	float present_avg_lum = rgb_to_gray(textureLod(colortools_and_ntsc_pass, vec2(0.5,0.5),20.0).rgb);
	
	//almost black screens:
	if (present_avg_lum < 5.0/255.0)
		return true;
	
	//scene changed:
	float past_avg_lum = rgb_to_gray(textureLod(colortools_and_ntsc_passFeedback, vec2(0.5,0.5),20.0).rgb);
	float diff_avg_lum = abs(past_avg_lum - present_avg_lum);
	return diff_avg_lum >= AMBI_SCENE_CHG_THRSHLD;
}


float screen_uniformity_wrap(){
	//wrap screen uniformity for deltarender support
	
	float current_uniformity = screen_uniformity();
	
	//no DR? -> update uniformity.
	if (vUniformity_return_current == 1.0)
		return current_uniformity;
	
	//DR enabled and scene changed, update uniformity.
	if (DR_uniformity_safe_update())
		return current_uniformity;
	
	//unreliable feedback, update uniformity.
	if (params.FrameCount < 10.0)
		return current_uniformity;
	
	//dr enabled and working, return feedback
	return texture(helper_passFeedback, vTexCoord).z;
	
}


void main() {
	
   #ifndef D3D_WORKAROUND
      if (is_skipped_frame())
         return;
   #endif
    
	bool smp_range_1  = is_first_inside_rect(vTexCoord, SMP_RANGE1 );
	
	FragColor = vec4(0.0);
	
	/*if ( smp_range_1 ) {
		//x
			FragColor.x = float(DO_CURVATURE * (GEOM_WARP_X + GEOM_WARP_Y) > 0.0 );
		//y
			#ifndef BEZEL_RES
				vec2 bezel_lut_size = textureSize(monitor_body_curved, 0);
				float bezel_frame_lod = log2(bezel_lut_size.y * (BEZEL_FRAME_ZOOM+1.0) * global.FinalViewportSize.w);
			#else
				//float bezel_frame_lod = log2(    fma( BEZEL_RES.y,  BEZEL_FRAME_ZOOM,  BEZEL_RES.y) * global.FinalViewportSize.w); //ASM PROOF: UNDECIDED
				float bezel_frame_lod = log2( BEZEL_RES.y * (BEZEL_FRAME_ZOOM+1.0) * global.FinalViewportSize.w); 
			#endif
			FragColor.y = bezel_frame_lod;
	}*/
	
	//Vignette/Spot:
		//Vignette defaults to 1.0 (multiplied in final pass), spot to 0.0 (added in final pass)
		FragColor.zw = vec2(1.0, 0.0); 
		
		if (DO_VIGNETTE == 1.0) {
			FragColor.z = screen_uniformity_wrap();
		}
		
		//Spot:
		if (DO_SPOT == 1.0) {
			float dist = length( vec2(  (vTexCoord_rotated_maybe.x-0.5) * vIn_aspect, vTexCoord_rotated_maybe.y-0.5) +
			                     vec2(   S_POSITION_X     * vIn_aspect, S_POSITION_Y) );
			FragColor.w = smoothstep(S_SIZE,0.0,dist) * S_POWER;
		}

}
