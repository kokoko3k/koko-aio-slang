#define alpha_mark 0.1
vec2 zoom(vec2 in_coords, float zoom_factor) {
   float off = 1.0/(zoom_factor*2.0) - 0.5;
   return (in_coords/zoom_factor)-off;
}

vec2 zoomout_coords(vec2 in_coords, float zoom_out, float aspect) {
   vec2 zoom   = vec2( 1 + zoom_out, 
                       1 + (zoom_out * aspect) 
                     );
                     
   vec2 offset = vec2( (zoom.x-1.0) / 2.0,
                       (zoom.y-1.0) / 2.0 
                     );
   return (in_coords * zoom) - offset;
}

bool scanline_have_to_flicker(bool is_interlaced) {
    return ((scanline_flickering == 1.0) || ((scanline_flickering==2.0) && is_interlaced ));
}

bool is_interlaced() {
	return (params.OriginalSize.y > MIN_LINES_INTERLACED);
}


#define RND_A 12.9898
#define RND_B 78.233
#define RND_C 43758.5453

float random(float power) {
    // www.stackoverflow.com/questions/5149544/can-i-generate-a-random-number-inside-a-pixel-shader/
    /*vec2 seed = vTexCoord * params.FrameCount;
    vec2 i = vec2(23.140692, 2.6651442);
    return fract(cos(dot(seed, i)) * 123456.0f);
    */
    
    //From pal-singlepass.slang 
    //https://github.com/svofski/CRT
    //Copyright (c) 2016, Viacheslav Slavinsky
    //All rights reserved.
    vec2 co = vTexCoord * params.FrameCount;
    float dt = dot(co.xy, vec2(RND_A, RND_B));
    float sn = mod(dt,3.14);

    float noise_out = fract(sin(sn) * RND_C) - 0.5;
    noise_out = clamp(noise_out, -power, power);
    return noise_out ; 
    
}


//CURVATURE
	#define corner_aspect vec2(1.0,  0.75)
	float border(vec2 coord)
	{
		coord = (coord - vec2(0.5)) + vec2(0.5, 0.5);
		coord = min(coord, vec2(1.0) - coord) * corner_aspect;
		vec2 cdist = vec2(GEOM_CORNER_SIZE);
		coord = (cdist - min(coord, cdist));
		float dist = sqrt(dot(coord, coord));
		return clamp((cdist.x - dist)*GEOM_CORNER_SMOOTH, 0.0, 1.0);
	}


	vec2 Warp(vec2 texCoord,float wx, float wy){
		vec2 curvedCoords = texCoord * 2.0 - 1.0;
		vec2 CRT_Distortion = vec2(wx, wy) * 15.;
		float curvedCoordsDistance = sqrt(curvedCoords.x*curvedCoords.x+curvedCoords.y*curvedCoords.y);

		curvedCoords = curvedCoords / curvedCoordsDistance;
		curvedCoords = curvedCoords * (1.0-pow(vec2(1.0-(curvedCoordsDistance/1.4142135623730950488016887242097)),(1.0/(1.0+CRT_Distortion*0.2))));
		curvedCoords = curvedCoords / (1.0-pow(vec2(0.29289321881345247559915563789515),(1.0/(vec2(1.0)+CRT_Distortion*0.2))));
		curvedCoords = curvedCoords * 0.5 + 0.5;
		
		return curvedCoords;
	}


//VIGNETTE - SPOT
/*	float gauss(float x, float x0, float sx, float size, float power){
		float arg = x-x0;
		arg = -(1/size)/2.*arg*arg/sx;
		float a = 1./(pow(2.*3.1415*sx, 0.5));
		return a*exp(arg) * power;
	}

	float gauss_xy(float pos_x, float pos_y, float size, float power, float gmin, float gmax) {
		vec2 uv = vTexCoord.xy + vec2(pos_x,pos_y);
		float scale_uv = params.SourceSize.x / params.SourceSize.y;
		float gx = gauss(uv.x* scale_uv,  0.5*scale_uv,  0.1,    size, power);
		float gy = gauss(uv.y,            0.5,           0.1,    size, power);
		float light = gx*gy;
		return clamp(light,gmin,gmax);
	}
*/

//AMBILIGHT RELATED
	bool border_needed() {
		//returns if we need to draw on the border
		return (DO_AMBILIGHT == 1.0);
	}

	
	#define mark_useless(x) mark_outer_frame(x)	
	vec4 mark_outer_frame(vec3 pixel) {
		return vec4(pixel.rgb,0.0) ;
		//For my mental sanity, I use a specific alpha channel value to mark a frame as a border
		return vec4(pixel.r,pixel.g,pixel.b,alpha_mark) ;
	}
	#define is_useless(x) is_outer_frame(x)
	bool is_outer_frame(vec4 pixel) {
		return pixel.a == 0.0;
		/*Check if a pixel is marked as border by comparing the value of its alpha channel
		Tolerance is needed, because precision can be as low as 1/256; since I don't need
		alpha channel, use an even large tolerance.
		*/
		return  abs(pixel.a - alpha_mark) < 0.05; //<-- 0.05 allow about 20 alpha levels (1*0.05)
	}

	#define ar_tolerance 0.1 //To compensate when comparing different A/R 
	bool is_rotated() {
		/*
			For some reason, probably retroarch rotates the view only on final viewport stage, transparent to the shader passes,
			The OutputSize of a pass that scales to viewport will have different aspect from the real final viewport.
			We exploit this to understand when a game is rotated.
			-->> This function only works if the calling pass scales to viewport.
			This will fail for very particular cases, eg: when output window is extremely tall 
		*/
		return (abs((params.OutputSize.x/params.OutputSize.y) - (global.FinalViewportSize.x/global.FinalViewportSize.y)) > ar_tolerance);
	}

	float get_in_aspect() {
			if (aspect_x ==  -1) return 1.5;   // ntsc
			if (aspect_x ==  -2) return 1.25;  // pal
			if (aspect_x ==  -3) return 1.143; // 8/7 snes
			if (aspect_x ==  -4) return 1.428; // 10/7 megadrive
			if (aspect_x ==  -5) return params.OriginalSize.x/params.OriginalSize.y; //uncorrected

			if (aspect_x == 0) {
				return 1.3333333333333; //all mame games, not rotated
			}

			return aspect_x / aspect_y ;
	}


	/*vec2 get_scaled_coords_old(vec2 pTexCoord, vec4 destsize, bool is_rotated){
		if (!border_needed()) return pTexCoord;
			//else
		float scale_x = 1.0;
		float scale_y = 1.0;
		float offset_x = 0.0 ;
		float offset_y = 0.0 ;
		float in_aspect = get_in_aspect();
		if (is_rotated) {
			//scale_y = params.OutputSize.y/(params.OutputSize.x / in_aspect );
			//scale_y = global.FinalViewportSize.y/(global.FinalViewportSize.x / in_aspect );
			scale_y = destsize.y/(destsize.x / in_aspect );
			offset_y = (0.5 * scale_y ) - 0.5 ;
			
			
		} else {
			//scale_x = params.OutputSize.x/(params.OutputSize.y * in_aspect);
			//scale_x = global.FinalViewportSize.x/(global.FinalViewportSize.y * in_aspect);
			scale_x = destsize.x/(destsize.y * in_aspect);
			offset_x = (0.5 * scale_x ) - 0.5 ;
		}

		vec2 scale_coord=vec2(pTexCoord.x*scale_x - offset_x , pTexCoord.y*scale_y - offset_y);
		return scale_coord;
	}*/


	vec2 get_scaled_coords(vec2 pTexCoord, vec4 destsize, bool is_rotated){
		if (!border_needed()) return pTexCoord;
			//else
		float scale_x = 1.0;
		float scale_y = 1.0;
		float offset_x = 0.0 ;
		float offset_y = 0.0 ;
		float in_aspect = get_in_aspect();
		if (is_rotated) {
			//I'm doing ping pong between th the following 2:
			//FIXME: verify if it depends on destsize being outputsize or finalviewportsize!!
			//scale_y = destsize.y/(destsize.x / in_aspect );
			scale_y = destsize.x/(destsize.y / in_aspect );
			
			offset_y = (0.5 * scale_y ) - 0.5 ;
			
			
		} else {
			//scale_x = params.OutputSize.x/(params.OutputSize.y * in_aspect);
			//scale_x = global.FinalViewportSize.x/(global.FinalViewportSize.y * in_aspect);
			scale_x = destsize.x/(destsize.y * in_aspect);
			offset_x = (0.5 * scale_x ) - 0.5 ;
		}

		vec2 scale_coord=vec2(pTexCoord.x*scale_x - offset_x , pTexCoord.y*scale_y - offset_y);
		return scale_coord;
	}
	
/*
float content_x_scale(){
    return params.OutputSize.x/(in_aspect * params.OutputSize.y);
}
*/

/*
float content_y_scale(){
    return 1.0;
}
*/

/*
float calc_offset_x(float uv_scale_x){
    return (0.5 * uv_scale_x ) - 0.5 ;
}
*/

/*
vec2 calc_uv() {
    vec2 uv_scale = vec2( content_x_scale() , content_y_scale() );
    vec2 uv ;
    uv.x = vTexCoord.x * uv_scale.x;
    uv.y = vTexCoord.y * uv_scale.y;

    float offset_x = calc_offset_x(uv_scale.x);
    uv.x = uv.x - offset_x ;

    return uv;
}
*/

/*bool coord_is_inside_frame(vec2 pixelcoord) {
    vec2 uv=calc_uv();
    float offset_x = calc_offset_x( content_x_scale() ) ;
    if (pixelcoord.x > offset_x)
        if (pixelcoord.x < 1.0-offset_x)
            return true;
    return false; //giallo

}
*/
































/*float HSM_GetScreenAspect(float screen_index, vec2 cropped_size)
{
	vec2 atari_lynx_res = 					vec2(160, 102);
	vec2 atari_2600_res = 					vec2(160, 228);
	vec2 atari_2600_crop_res = 				vec2(152, 228);
	vec2 nintendo_gameboy_advance_res = 	vec2(240, 160);
	vec2 nintendo_gameboy_res = 			vec2(160, 144);
	vec2 nintendo_ds_res = 					vec2(256, 192);
	vec2 nintendo_ds_top_bottom_res = 		vec2(256, 384);
	vec2 nintendo_ds_side_by_side_res = 	vec2(512, 192);
	vec2 nintendo_3ds_top_res = 			vec2(400, 240);
	vec2 nintendo_3ds_bottom_res = 			vec2(320, 240);
	vec2 nintendo_3ds_top_bottom_res = 		vec2(400, 480);
	vec2 nintendo_3ds_side_by_side_res = 	vec2(720, 240);
	vec2 sega_saturn_fmv_res = 				vec2(352, 480);
	vec2 sony_psp = 						vec2(480, 272);
	vec2 sony_ps_fmv_res = 					vec2(320, 480);
	vec2 sony_ps_fmv_res_2 = 				vec2(512, 480);

	// This should handle some PS games with weird resolutions like Tekken and Driver
	float sony_ps_height = 448;

	if (HSM_ASPECT_RATIO_MODE == 0)
	{
		// If the vertical res is larger than 580 is is probably a modern square pixel resolution
		// 576 seems to be PAL vertical resolution used sometimes
 		if (original_size.y > 580) horizontal_aspect = core_aspect_horizontal;
		else if (HSM_ResolutionIsEqual(sony_psp, 						original_size)) horizontal_aspect = core_aspect_horizontal;
		else if (HSM_ResolutionIsEqual(nintendo_gameboy_advance_res, 	original_size)) horizontal_aspect = core_aspect_horizontal;
		else if (HSM_ResolutionIsEqual(nintendo_gameboy_res, 			original_size)) horizontal_aspect = core_aspect_horizontal;
		else if (HSM_ResolutionIsEqual(nintendo_ds_res, 				original_size)) horizontal_aspect = core_aspect_horizontal;
		else if (HSM_ResolutionIsEqual(nintendo_ds_top_bottom_res, 		original_size)) horizontal_aspect = core_aspect_horizontal;
		else if (HSM_ResolutionIsEqual(nintendo_ds_side_by_side_res, 	original_size)) horizontal_aspect = core_aspect_horizontal;
		else if (HSM_ResolutionIsEqual(nintendo_3ds_top_res, 			original_size)) horizontal_aspect = core_aspect_horizontal;
		else if (HSM_ResolutionIsEqual(nintendo_3ds_bottom_res, 		original_size)) horizontal_aspect = core_aspect_horizontal;
		else if (HSM_ResolutionIsEqual(nintendo_3ds_top_bottom_res, 	original_size)) horizontal_aspect = core_aspect_horizontal;
		else if (HSM_ResolutionIsEqual(nintendo_3ds_side_by_side_res, 	original_size)) horizontal_aspect = core_aspect_horizontal;
		else if (HSM_ResolutionIsEqual(atari_lynx_res, 					original_size)) horizontal_aspect = core_aspect_horizontal;
		else if (HSM_ResolutionIsEqual(atari_2600_res, 					original_size)) horizontal_aspect = 1.333;
		else if (HSM_ResolutionIsEqual(atari_2600_crop_res, 			original_size)) horizontal_aspect = 1.333;
		else if (HSM_ResolutionIsEqual(sony_ps_fmv_res, 				original_size)) horizontal_aspect = 1.333;
		else if (HSM_ResolutionIsEqual(sony_ps_fmv_res_2, 				original_size)) horizontal_aspect = 1.333;
		else if (original_size.y == sony_ps_height) 									horizontal_aspect = 1.333;
		// Fall back to the explicit ratio
		else horizontal_aspect = HSM_ASPECT_RATIO_EXPLICIT;
	}
	else
		if (HSM_ASPECT_RATIO_MODE == 1) horizontal_aspect = HSM_ASPECT_RATIO_EXPLICIT;
		else if (HSM_ASPECT_RATIO_MODE == 2) horizontal_aspect = 1.3333;
		else if (HSM_ASPECT_RATIO_MODE == 3) horizontal_aspect = 1.5;
		else if (HSM_ASPECT_RATIO_MODE == 4) horizontal_aspect = 1.7777;
		else if (HSM_ASPECT_RATIO_MODE == 5) horizontal_aspect = cropped_size.x / cropped_size.y;
		else if (HSM_ASPECT_RATIO_MODE == 6) horizontal_aspect = global.FinalViewportSize.x / global.FinalViewportSize.y;
		else horizontal_aspect = 1.333;

	// Find what the vertical aspect would be, either the current horizontal_aspect (if it's already vertical)
	// Or changing the horizontal aspect to vertical by taking the reciprocal
	float vertical_aspect = 1 / horizontal_aspect;
	float final_orientation = HSM_ASPECT_RATIO_ORIENTATION;

	if (HSM_ASPECT_RATIO_ORIENTATION < 0.5)
	{
		// Catch for Atari 2600 - Stella Emulator which would otherwise show up as a vertical aspect ratio
		if (
				HSM_ResolutionIsEqual(atari_2600_res, original_size) ||
		   		HSM_ResolutionIsEqual(atari_2600_crop_res, original_size) ||
		   		HSM_ResolutionIsEqual(sega_saturn_fmv_res, original_size) ||
				HSM_ResolutionIsEqual(sony_ps_fmv_res, original_size) ||
				HSM_ResolutionIsEqual(sony_ps_fmv_res_2, original_size) ||
				original_size.y == sony_ps_height
		   )
		{
		   final_orientation = 1;
		}
		else
		{
			final_orientation = (HSM_GetIsCorePreppedSizeVertical(screen_index) > 0.5) ? 2 : 1;
		}
	}

	float final_aspect_ratio = (final_orientation < 1.5) ? horizontal_aspect : vertical_aspect;

	return final_aspect_ratio;
}*/

/*

Amiga: no guess
320x224 = megadrive = 10/7

Se fallisce il guess, fallback a 4:3 o 3:4


aggiungi opzioni negative per:
-1 = ntsc - 1.5
-2 = pal  - 1.25
-3 = 8/7 (snes)
-4 = 10/7 (megadrive)
-5 = uncorrected


  PAL = 1.25
  NTSC = 1.5

  Megadrive ntsc:
    //picodrive sets 1.43 (256/179) originalsize = 320x224 (pal and ntsc)
    //genesis plus gx sets 1.3 (256/196) originalsize = 320x224 (pal and ntsc)
    Aspect: ntsc, pal o 10/7

  SNES:
    Aspect:
		Uncorrected 256/224 (8/7), pal o ntsc, preferenza utente.
    Source resolution per snes9x: 512x448
    256*224 (crop enabled)
	256*239 (crop disabled)
	512*224 (crop enabled)
	512*239 (crop disabled)
	512*448 (crop disabled, interlace)
	512*478 (crop enabled, interlace)




    if ( aspect_x == 0 ) {
        /*AMIGA - PUAE
        Cropping res (PAL):
        720x288
        720x270
        696x264
        672x256
        640x240
        640x224
        640x216
        640x200

*/

