#version 450

#include "config.inc"

#include "includes/functions.include.slang"

#pragma stage vertex
layout(location = 0) in vec4 Position;
layout(location = 1) in vec2 TexCoord;
layout(location = 0) out vec2 vTexCoord;
layout(location = 1) out float vIn_aspect;

void main() {
	gl_Position = global.MVP * Position;
	vTexCoord = TexCoord;
	vIn_aspect = get_in_aspect();
}

#pragma stage fragment

layout(location = 0) in vec2 vTexCoord;
layout(location = 1) in float vIn_aspect;

layout(location = 0) out vec4 FragColor;
layout(set = 0, binding = 2) uniform sampler2D monitor_body_curved;





void main() {
	
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
	
	//Vignette:
	if (DO_VIGNETTE == 1.0) {
		vec2 sinco = cos((vTexCoord-0.5) / V_SIZE) ;
		FragColor.z = V_POWER * (sinco.y * sinco.x);
	}
	//Spot:
	if (DO_SPOT == 1.0) {
		float dist = length( vec2(  (vTexCoord.x-0.5) * vIn_aspect, vTexCoord.y-0.5) +
								vec2(   S_POSITION_X      * vIn_aspect, S_POSITION_Y) );
		FragColor.w = smoothstep(S_SIZE,0.0,dist) * S_POWER;
		
	}

}
