
// BEZEL STATIC CONFIG ##############################################################################################
	//The following defines the monitor frame resolution in textures/monitor_body_[curved/straight].png
	//and are used to calculate the sampling lod.
	//Change if you change the texture resolution or
	//you can comment it to let the shader calculates them at runtime (heavier).
#define BEZEL_RES vec2(2923, 2178)

	//The following can slightly correct bezel aspect
#define BEZEL_ASPECT_CORRECTION (1.0 - 0.004)

	//This is used to skip calculations in the reflection blur code.
	//set it to minimum value that allows you to see reflection entirely
#define BEZEL_REFL_SKIP_SIZE 0.08

	//This is the size (in 0..1 range) of the bezel texture that does
	//not include the center tube, including reflection area, and the shadow.
	//It is actually used to skip drawing game content under the bezel or
	//over its shadow.
	//Set it to the maximum size as long as you see the full game content
	//in the bezel.
#define BEZEL_BORDER_SIZE vec2(0.07, 0.07)

	//This is the blank area or shadow size (one side, in percent) at the sides of the bezel as defined by the bezel texture
	//BEZEL_SHADOW_SIZE = max shadow or blank side size / bezel_texture_size.
	//It is used to skip drawing bg/fg or ambient light over the tube, set it to a value that allow for them to be 
	//shown over the bezel blank/shadowed sides but not on the tube (ie: value too big)
#define BEZEL_SHADOW_SIZE 0.06

	//to speedup things, bezel rende logic can be completely skipped in the inner tube, if we
	//already know it is completely transparent.
	//Set the following to the maximum value that allow you to see 
	//bezel borders and, if present in the source bezel texture, inner content/border shades
#define BEZEL_TUBE_BLANK_SIZE 0.88

	//In the second reflection pass, the coordinates are zoomedout by the
	//BEZEL_REFL_ZOOMOUT_ROOM so that the image is mirrored-repeated by retroarch.
	//they are adjusted by an inverse amount in final pass to align them
	//lowering this value makes more room for reflections, but this steals
	//pixels for reflection resolution, so make it higher as possible as
	//long as you can see the reflections on the reflective area without
	//them blanking or repeating.
	//Modifying it require you to tweak BEZEL_REFL_CORNER_BLANK_SIZE too.
#define BEZEL_REFL_ZOOMOUT_ROOM 0.8


	// Define the size and the smoothness of the rectangle 
	// in the bezel corners that will hide and blur the reflections 
#define BEZEL_REFL_CORNER_BLANK_SIZE 0.091
#define BEZEL_REFL_CORNER_BLANK_SHADE 0.055  // keep it > 0.0


	//When colorizing the bezel via ambient light, it is possible to choose where 
	//the colorization ends. depending on the bezel texture/lut used, the following
	//parameter wil allow to colorize top/bottom and left/right border with the
	//same shade amount.
#define AMBI_OVER_BEZEL_AR_CORRECTION 0.98



// AMBIENT LIGHT STATIC CONFIG ##########################################################################################

	// 0.0-1.0: sensitivity to scene change (ambilike stuff), 0.0 changes more
#define AMBI_SCENE_CHG_THRSHLD 0.07  
	// The following will allow to sample at reduced interval
	// The scene change detection logic will take advantage of it
	// So that quick fades will still be treated as scene changes
#define AMBI_AVGLUM_DIVIDER 3

	// The following defines the speed of the color fades 
	// when changing scene. (range 0..1)
	// It is wise to correlate it with avglum_divider
	// try between (1/avglum_divider) and (1/avglum_divider)/3
//#define AMBI_FAST_STEP 0.125
#define AMBI_FAST_STEP 0.25







// GLOW STATIC CONFIG ##########################################################################################

	//Setting the glow/halo sharpness parameter to this
	//will skip the blurring phase and lowers the gpu use
	//Set this to the same value as used for the maximum
	//of IN_GLOW_W/H, HALO_SHARPNESS
#define GLOW_SHARP_MAX 7	        

	//Minumum glow sharpness
	//I set this to allow negative values for glow sharpness
	//that will calc their values from light spread amount
#define MIN_IN_GLOW_SHARP 0.40

	//Setting glow to blur bias parameter to this will skip the glow/blur 
	//mix code and just return the blurred image
	//Set this to the same value as used for the maximum for IN_GLOW_BIAS pragma
#define IN_GLOW_BIAS_MAX 1.0

	//Try to keep blur sizes consistent across input resolutions
#define SCALEMOD_X 360
#define SCALEMOD_Y 270
#define NEW_SCALEMOD_X (global.flick_and_noise_passSize.x/(360.0*2.0) / 2.2)
#define NEW_SCALEMOD_Y (global.flick_and_noise_passSize.y/(270.0*2.0) / 2.2)



// MISC STATIC CONFIG ##########################################################################################

	//Experimental alternating blanking feature has been disabled by default, you can enable it by
	//uncommenting the following line:
//#define ALLOW_ALT_BLANK

	//Halve rendering refresh on bezel and ambilight to spare gpu cycles:
#define HALVE_BORDER_UPDATE 1.0

	//Renders only changed parts of screen.
#define DELTA_RENDER 0.0

	//Static dithering applied over vignette and spot
#define NOISEPOWER 5/1000.0
	//Temporal noise strength applied on green over ambient lights (multiplied by NOISEPOWER)
#define NOISEPOWER_AMBI_MUL 8.0
	
	//Should texture wrapping be allowed as a shader parameter?
	//since it causes branching, better set it as a static value.
#define ALLOW_BG_IMAGE_TEXTURE_WRAP_IN_SHADER

	//Gap size in pixel for 1X to 4X mask scaling:
#define GAP_SIZE_PER_SCALE vec4(1.0, 1.0, 2.0, 2.0)


// STATIC CONFIG ENDS HERE ##########################################################################################








#define eps 1e-5
#define pi  3.141592653589793
#define TAU 6.28318530717958647693
#define alpha_mark 0.1


layout(push_constant) uniform Push {
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	vec4 final_passSize;
	uint FrameCount;

	float HALO_SHARPNESS ;
	float HALO_NO_PREGAIN;
	float HALO_POWER ;
	float HALO_GAMMA ;
	float HALO_GAMMA_OUT;
	float HALO_VS_SCAN ;
	float DO_BLOOM ; //4
 	float BLOOM_QUALITY ; //1
	float AMBI_ADD_ON_BLACK;
	float AMBI_STRETCH;
	float AMBI_INT_OFFSET ;
	
} params;

layout(std140, set = 0, binding = 0) uniform UBO {
	mat4 MVP;
	
	vec4 FinalViewportSize;
	vec4 in_glow_passSize;
	vec4 FXAA_passSize;

	vec4 avglum_passSize;
	vec4 flick_and_noise_passSize;
	vec4 colortools_and_ntsc_passSize;

	float COLOR_MONO_COLORIZE;
	float COLOR_MONO_HUE1;
	float COLOR_MONO_HUE2;
	float COLOR_MONO_HUE_BIAS;
	
	float DO_IN_GLOW;

	float DO_HALO ;
	float DO_CCORRECTION;
	float DO_ALT_BLANK;
	float IN_GLOW_BIAS ;
	float IN_GLOW_SPREAD ;

	float IN_GLOW_W;
	float IN_GLOW_H;
	float IN_GLOW_POWER;
	float IN_GLOW_GAMMA;
	
	float BLOOM_MIX;
	float BLOOM_EYE_ADPT_SRT;
	float BLOOM_EYE_INERTIA;
 	float BLOOM_SIZE;
	float BLOOM_GAMMA;
	float BLOOM_BYPASS;
	float BLOOM_POWER;
	float BLOOM_OVER_WHITE;
  	float BLOOM_GAMMA_OUT;
  	float ALT_BLANK_STRENGTH;
  	float ALT_BLANK_PERIOD;
	
	float DO_FXAA;
	
	float DO_SAT_BLEED;
	float SAT_BLEED_SIZE_LEFT;
	float SAT_BLEED_SIZE_RIGHT;
	float SAT_BLEED_FALLOFF;
	float SAT_BLEED_STRENGTH;
	float SAT_BLEED_PAL;
	

	

	float GAMMA_OUT ;
	float SATURATION;
	float LUMINANCE;
	float CONTRAST;
	float BRIGHTNESS;
	float TEMPERATURE;
	
	float DO_CURVATURE;
	float GEOM_WARP_X;
	float GEOM_WARP_Y;
	float GEOM_CUT_EARS;
	float GEOM_CORNER_SIZE;
	float GEOM_CORNER_SMOOTH;

	float DO_BEZEL;
	float BEZEL_R;
	float BEZEL_G;
	float BEZEL_B;
	float BEZEL_CON;
	float BEZEL_INNER_ZOOM;
	float BEZEL_FRAME_ZOOM;
	float BEZEL_USE_STRAIGHT;
	float BEZEL_RFL_BLR_SHD;
	float BEZEL_RFL_ZOOM;
	float BEZEL_REFL_STRENGTH;
	float BEZEL_DIFFUSION_STR;
	float BEZEL_SPCL_STRENGTH;
	float BEZEL_ROUGHNESS;
	float BEZEL_CORNER_DARK;
	
	float DO_SPOT;
	float S_POSITION; 
	float S_SIZE;
	float S_POWER;

	float DO_VIGNETTE;
	float V_SIZE;
	float V_POWER;

	float DO_DYNZOOM;
	float DYNZOOM_FACTOR;
	
	float DO_AMBILIGHT;
	float AMBI_FALLOFF;
	float AMBI_POWER;
	float AMBI_GAMMA;

	float AMBI_OVER_BEZEL;
	float AMBI_OVER_BEZEL_SIZE;
	float AMBI_STEPS;
	float AMBI_BG_IMAGE_BLEND_MODE;
	float AMBI_BG_IMAGE_FORCE;

	
	float ASPECT_X;
	float ASPECT_Y;
	
	float DO_BG_IMAGE;
	float BG_IMAGE_OVER;
	float BG_IMAGE_OFFY;
	float BG_IMAGE_OFFX;
	float BG_IMAGE_ZOOM;
	float BG_IMAGE_ROTATION;
	float BG_IMAGE_NIGHTIFY;
	float BG_IMAGE_WRAP_MODE;

	float DO_SHIFT_RGB;
	float SHIFT_R;
	float SHIFT_G;
	float SHIFT_B;
	float OFFSET_STRENGTH;
	
	float DO_GLOBAL_SHZO;
	float GLOBAL_ZOOM;
	float GLOBAL_OFFX;
	float GLOBAL_OFFY;

	float DO_RF_NOISE;
	float RF_NOISE_STRENGTH;
	
	float DO_GAME_GEOM_OVERRIDE;
	float GAME_GEOM_INT_SCALE;
	float GAME_GEOM_INT_SCALE_MAX;
	float GAME_GEOM_ASPECT;
	float GAME_GEOM_VSHIFT;
	float GAME_GEOM_HSHIFT;
	float GAME_GEOM_ZOOM;
	float GAME_GEOM_OFF_FIX; 
	
	float DO_TILT;
	float TILT_X;
	float TILT_Y;
	float TILT_BEZEL_K;
	float TILT_FOV;
	
	float DO_BACKDROP; 
	float BACKDROP_OFFX;
	float BACKDROP_OFFY;
	float BACKDROP_ZOOM;
	
	
	float TATE;

	float DO_DOT_MATRIX;
	float DOT_M_G_SHARP;
	float DOT_M_G_TRESH;
	float DOT_M_G_STR;
	float DOT_M_G_BRT;
	float DOT_M_RGB_SHARP;
	float DOT_M_RGB_STR;
	float DOT_M_G_GAIN;
	float DOT_M_MBLUR_STR;
	float DOT_M_MBLUR_MODE;
	float DOT_M_MULTIPLY;
	float DOT_M_SHADOW_STR;
	float DOT_M_SHADOW_OFF;
	
	float MIN_LINES_INTERLACED;
	float DO_PIXELGRID;
	float PIXELGRID_OVERMASK;
	float DO_PIXELGRID_W;
	float DO_PIXELGRID_H;
	float PIXELGRID_MIN_H;
	float PIXELGRID_MIN_W;
	float PIXELGRID_MAX_H;
	float PIXELGRID_MAX_W;
	float PIXELGRID_SIZE_W;
	float PIXELGRID_SMOOTH_H;
	float PIXELGRID_SMOOTH_W;

	float PIXELGRID_MUL_X;
													
	float PIXELGRID_OFFSET_CORE;
	float PIXELGRID_NO_INTERBLEED_W;
	float PIXELGRID_NO_INTERBLEED_H;
	float PIXELGRID_H_DEDOT;
	
	float PIXELGRID_INTR_FLICK_MODE;
	float PIXELGRID_INTR_FLICK_POWR;
	float PIXELGRID_INTR_DISABLE_Y;
	
	
	float PIXELGRID_DECON_R_H;
	float PIXELGRID_DECON_G_H;
	float PIXELGRID_DECON_B_H;
	
	float PIXELGRID_Y_MASK;
	float PIXELGRID_Y_MASK_ON_WHITE;
	float PIXELGRID_Y_MASK_HEIGHT;
	float PIXELGRID_Y_MASK_OFFSET;
	float PIXELGRID_Y_MASK_STEEP;
	float PIXELGRID_Y_MASK_COORDS;
	float PIXELGRID_Y_MASK_SHIFT;
	float PIXELGRID_Y_SPARK;
	float PIXELGRID_R_SHIFT;
	float PIXELGRID_G_SHIFT;
	float PIXELGRID_B_SHIFT;
	float PIXELGRID_H_COUNT;
	float PIXELGRID_H_PRST;
	float PIXELGRID_GAMMA_H;
	float PIXELGRID_GAMMA_W;
	//float PIXELGRID_HMASK_NO_BRIGHT;
	float PIXELGRID_BASAL_GRID;
	float DELTA_RENDER_FORCE_REFRESH;
	float DELTA_RENDER_CHECK_AREA;
	

	float DO_NTSC_ARTIFACTS;
	float NTSC_FILTER_WIDTH;
	float NTSC_FILTER_SCF;
	float NTSC_FILTER_FC;
	float NTSC_MIX;
	float NTSC_PHASE_SHIFT;

	float NTSC_ARTF_NOBLEED;
	float NTSC_ARTF_NOBLUR;
	float NTSC_ARTF_TRSH;
	float NTSC_SHOW_ARTF_MASK;
	float NTSC_ARTF_ZAP;
	
	float SERVICE1;
	
	
	

	
} global;


// Color correction
#pragma parameter DO_CCORRECTION "★ Color corrections enable? (co) ==>" 		0.0 	0.0 1.0 1.0
#pragma parameter IN_GLOW_POWER  "       Input signal gain (was in glow section):"					1.0 	0.0 5.0 0.05
#pragma parameter LUMINANCE       "       Luminance push (>1.0=clip)"		0.0	 0.0 1.5 0.05
#pragma parameter BRIGHTNESS     "        Brightness in   (0.0=off)"		0.0	-1.0 1.0 0.01
#pragma parameter CONTRAST       "        Contrast in     (0.0=off)"		0.0	-1.0 1.0 0.01
#pragma parameter TEMPERATURE    "        Temperature in (6500=off)"		6500.0	3000 14000.0 50.0
#pragma parameter IN_GLOW_GAMMA  "        Gamma In  (applied at the beginning)"		1.0 	1.0 	10.0 0.1
#pragma parameter GAMMA_OUT      "        Gamma out (applied at the end)"			0.69	0.1 	4.0  0.01
#pragma parameter COLOR_MONO_COLORIZE	"        Monochrome screen colorization"	0.0  0.0 1.0 0.1
#pragma parameter COLOR_MONO_HUE1        "           . Hue bright"					0.25 0.0 1.0 0.01
#pragma parameter COLOR_MONO_HUE2        "           . Hue dark"						0.3  0.0 1.0 0.01
#pragma parameter COLOR_MONO_HUE_BIAS    "           . Hue bright-dark bias"		0.0	-2.0 2.0 0.01
#pragma parameter SATURATION     "        Saturation in   (1.0=off)"		1.0	0.0  2.0 0.01
#pragma parameter BLANK1 " " 0.0 0.0 1.0 1.0



// FXAA
// Apply an antialiasing filter via FXAA from Nvidia.
#pragma parameter DO_FXAA "★ FXAA enable? (*f) ==>"	0.0 	0.0 1.0 1.0
#pragma parameter BLANK2 " " 0.0 0.0 1.0 1.0

// RF Noise
#pragma parameter DO_RF_NOISE	 "★ RF Noise enable? (rf) ==>"			0.0 	0.0  1.0     1.0
#pragma parameter RF_NOISE_STRENGTH "        Strength"				0.05	0.0 1.0 0.005
#pragma parameter BLANK4 " " 0.0 0.0 1.0 1.0

// NTSC color artifacting
#pragma parameter DO_NTSC_ARTIFACTS "★ CVBS: NTSC color artifacts enable? (nt) ==>"	0.0 	0.0 1.0 1.0
#pragma parameter NTSC_MIX          "        Strength"				0.5	0.0 3.0  0.1
#pragma parameter NTSC_FILTER_WIDTH "        Filter width"			17.0	5.0 21.0 4.0
#pragma parameter NTSC_FILTER_SCF   "        Subcarrier Frequency"		5.30	0.0 10.0 0.01
#pragma parameter NTSC_FILTER_FC    "        Frequency cutoff"			2.5	0.0 10.0 0.1
#pragma parameter NTSC_PHASE_SHIFT  "        Phase shift"			0.0	0.0 1.0  1.0
#pragma parameter label_blut_ntsc   "        1 and 2 need Glow or Bandwidth Limited chroma" 0.0 0.0 0.0 0.0
#pragma parameter NTSC_ARTF_TRSH      "      . Consider artifacts above this treshold"			0.1	0.0 1.0 0.01
#pragma parameter NTSC_SHOW_ARTF_MASK "         . Show the mask of selected artifacts (debug)"				0.0	0.0 1.0 1.0
#pragma parameter NTSC_ARTF_NOBLUR    "         . 1* Under treshold: Cancel blur (Glow)"				0.0	0.0 8.0 0.01
#pragma parameter NTSC_ARTF_NOBLEED   "         . 2* Under treshold: Cancel Bandwidth limited chroma"	0.0	0.0 1.0 0.01
#pragma parameter NTSC_ARTF_ZAP       "         . 3* Under treshold: Cancel artifacts"					0.0	0.0 1.0 0.01

#pragma parameter BLANK3 " " 0.0 0.0 1.0 1.0


// YIQ/YUV bandwidth limited chroma bleeding.
#pragma parameter DO_SAT_BLEED "★ CVBS: Bandwidth limited chroma enable? (cv) ==>"	0.0 	0.0 1.0 1.0
#pragma parameter SAT_BLEED_PAL           "        Use PAL colorspace, not NTSC"	0.0 	 0.0 1.0 1.0
#pragma parameter SAT_BLEED_STRENGTH      "        Strength"				1.0	 0.0 5.0  0.01
#pragma parameter SAT_BLEED_SIZE_LEFT     "        Size Left"				5.0 	 1.0 40.0  1.0
#pragma parameter SAT_BLEED_SIZE_RIGHT    "        Size Right"				5.0 	 1.0 40.0  1.0
#pragma parameter SAT_BLEED_FALLOFF  	  "        Falloff"				1.7 	 1.0 2.0 0.01
#pragma parameter BLANK5 " " 0.0 0.0 1.0 1.0



//Deconvergence
#pragma parameter DO_SHIFT_RGB       "★ Deconvergence enable? (de) ==>"	0.0	 0.0 1.0 1.0
#pragma parameter OFFSET_STRENGTH "        Strength"			0.6 	 0.0 1.0 0.05
#pragma parameter SHIFT_R         "        Red offset"			-40.0 	-210.0 189.0 1
#pragma parameter SHIFT_G         "        Green offset"		2.0 	-210.0 189.0 1
#pragma parameter SHIFT_B         "        Blue offset"			40.0 	-210.0 189.0 1
#pragma parameter BLANK6 " " 0.0 0.0 1.0 1.0



// Input Blur / light glowing
#pragma parameter DO_IN_GLOW               "★ Glow/Blur enable? (gl) ==>"	 					0.0	0.0 1.0 1.0
#pragma parameter IN_GLOW_BIAS             "        Glow to blur bias"							1.0     0.0 1.0 0.05
#pragma parameter IN_GLOW_SPREAD           "        Glow spread amount"		0.6 	0.0 4.0 0.05
#pragma parameter IN_GLOW_W                "        Sharp X (neg=use BOX unsharp)"		2.5	-2.0 7.0 0.05
#pragma parameter IN_GLOW_H                "        Sharp Y (neg=use BOX unsharp)"		2.5	-2.0 7.0 0.02
#pragma parameter BLANK7 " " 0.0 0.0 1.0 1.0


#pragma parameter TATE                     "★ Tate mode (0:disabled 1:auto 2:forced)"		0.0 	0.0 2.0 1.0
#pragma parameter BLANK7a " " 0.0 0.0 1.0 1.0


// pixel Grid
#pragma parameter DO_PIXELGRID		 "★  Low level Phosphor grid enable? (ph) ==>"	0.0 0.0 1.0 1.0
#pragma parameter PIXELGRID_OVERMASK "      Overmask (1.0 = neutral)"	1.0 0.0 2.0 0.02

#pragma parameter DO_PIXELGRID_W     "      ★ Horizontal mask (0 to disable)"    	1.0 0.0 1.0 0.05
#pragma parameter PIXELGRID_SIZE_W   "           . Resolution: (core or screen)"	1.0 0.0 1.0 1.0
#pragma parameter PIXELGRID_H_PRST   "           . Mask type preset (0: for manual)"  3.0 0.0 7.0 1.0
#pragma parameter PG_LABEL1          "             (1:gm 2:gmx 3:rgb 4:rgbx 5:rbg 6:rbgx 7:wx)"  0.0 0.0 0.0 0.0
#pragma parameter PIXELGRID_H_COUNT  "                . 0: Phosphors+gap count (mask size)"	3.0 1.0 4.0  1.0
#pragma parameter PIXELGRID_R_SHIFT  "                . 0: R phospor position"      0.0  0.0 4.0 0.1
#pragma parameter PIXELGRID_G_SHIFT  "                . 0: G phospor position"      1.0  0.0 4.0 0.1
#pragma parameter PIXELGRID_B_SHIFT  "                . 0: B phospor position"      2.0  0.0 4.0 0.1
#pragma parameter PIXELGRID_MIN_W    "           . Phosphors width Min"			0.25 0.05 1.0 0.01
#pragma parameter PIXELGRID_MAX_W    "           . Phosphors width Max"			0.25 0.05 1.0 0.01
#pragma parameter PIXELGRID_GAMMA_W  "           . Phosphors width min->max gamma:"	4.2 1.0 8.00 0.1
#pragma parameter PIXELGRID_MUL_X    "           . Cell size multiplier x (neg=divider):"	1.0 -8.0 8.0 0.125
//#pragma parameter PIXELGRID_HMASK_NO_BRIGHT  "           . Fade on bright"	0.0 0.0 1.0 0.01
#pragma parameter PIXELGRID_NO_INTERBLEED_W	"           . Inter-cell extra steepness"		0.0 0.0 10.0 0.1
#pragma parameter PIXELGRID_BASAL_GRID  "           . Black level of the unexcided phosphor grid"	0.0 0.0 10.0 0.01
#pragma parameter BLANK12fs " " 0.0 0.0 1.0 1.0



#pragma parameter DO_PIXELGRID_H            "      ★ Scanlines (0 to disable)"    	1.0 0.0 1.25 0.05
#pragma parameter PIXELGRID_MIN_H	        "           . Phosphors height Min"			0.2 0.00 1.0 0.05
#pragma parameter PIXELGRID_MAX_H           "           . Phosphors height Max"			0.6 0.0 1.5 0.05
#pragma parameter PIXELGRID_GAMMA_H         "           . Phosphors height min->max gamma:"	4.2 1.0 8.00 0.1
#pragma parameter PIXELGRID_OFFSET_CORE     "           . Slotmask(-fake) offset (low => anti-moiree)" 0.0 0.0 1.0 0.01
#pragma parameter PIXELGRID_NO_INTERBLEED_H	"           . Inter line extra steepness"		0.0 0.0 10.0 0.1
#pragma parameter PIXELGRID_H_DEDOT			"           . Dedot mask between scanlines (use only if needed!)"	0.0 0.0 1.0 0.1
#pragma parameter PIXELGRID_DECON_R_H       "           . Deconvergence Y: R phosphor" 0.0 -1.6 1.6 0.1
#pragma parameter PIXELGRID_DECON_G_H       "           . Deconvergence Y: G phosphor" 0.0 -1.6 1.6 0.1
#pragma parameter PIXELGRID_DECON_B_H       "           . Deconvergence Y: B phosphor" 0.0 -1.6 1.6 0.1


#pragma parameter BLANK12f " " 0.0 0.0 1.0 1.0

#pragma parameter MIN_LINES_INTERLACED      "        Interlace detect + Scanline alternate above # lines:"		380.0 	1.0 1024 1.0
#pragma parameter PIXELGRID_INTR_DISABLE_Y  "        Disable scanlines on interlaced screen"			  	0.0 	0.0 1.0 1.0
#pragma parameter PIXELGRID_INTR_FLICK_MODE "        Interlace Flicker (0=off,1=on,2=if interlaced)"		2.0 	0.0 2.0 1.0
#pragma parameter PIXELGRID_INTR_FLICK_POWR "           . Interlace Flicker power"		  		0.25 	0.0 8.0 0.01


#pragma parameter BLANK12e " " 0.0 0.0 1.0 1.0

#pragma parameter PIXELGRID_Y_MASK           "      ★ Vertical cell Mask (0 to disable)"	0.5 0.0 1.0 0.05
#pragma parameter PIXELGRID_Y_MASK_COORDS    "           . Resolution: (core or screen)"	1.0 0.0 1.0 1.0
#pragma parameter PIXELGRID_Y_MASK_HEIGHT    "           . Height divider (neg=multiplier):"	0.5 -8.0 8.0 0.125
#pragma parameter PIXELGRID_Y_MASK_ON_WHITE  "           . Fadeout under light"	0.5 0.0 1.0 0.01
#pragma parameter PIXELGRID_Y_MASK_OFFSET    "           . Even/odd offset"	1.0 0.0 1.0 1.0
#pragma parameter PIXELGRID_Y_MASK_SHIFT     "             . Vertical shift (for use with core resolution)"	0.0 0.0 1.0 0.01
#pragma parameter PIXELGRID_Y_MASK_STEEP     "           . Steepness"	2.0 1.0 30.0 1.0
#pragma parameter PIXELGRID_Y_SPARK          "           . Sparkling look punch"	0.0 0.0 1.0 0.05

#pragma parameter BLANK12d " " 0.0 0.0 1.0 1.0




// Dot matrix emulation
#pragma parameter DO_DOT_MATRIX		"★  Dot matrix emulation enable? (NOT with scanlines!) ==>"	0.0 0.0 1.0 1.0
#pragma parameter DOT_M_G_STR		"        Grid strength"					0.0 0.0 1.0 0.01
#pragma parameter DOT_M_G_TRESH		"           . Paint on bright (<0 on black)"	1.1 -1.1 1.1 0.01
#pragma parameter DOT_M_G_BRT		"           . Grid brightness"					0.0 0.0 1.0 0.01
#pragma parameter DOT_M_G_SHARP		"           . Grid sharpness (0.0 for auto)"	0.0 0.0 20.0 0.25
#pragma parameter DOT_M_MBLUR_STR	"        Refresh inertia"				0.45  0.0 0.9 0.05
#pragma parameter DOT_M_MBLUR_MODE  "           . Inertia on: both,white,black"	0.0  0.0 2.0 1.0
#pragma parameter DOT_M_SHADOW_STR  "        Shadow strength (disables deconvergence)"	0.0  0.0 1.0 0.01
#pragma parameter DOT_M_SHADOW_OFF  "           . Shadow offset"								0.0  -1.0 1.0 0.01
#pragma parameter DOT_M_MULTIPLY	"        Multiply factor (debug)"		1.0  1.0 50.0 1.0
#pragma parameter BLANK12c " " 0.0 0.0 1.0 1.0




// Halo
#pragma parameter DO_HALO         "★ Halo enable? (ha) ==>" 						0.0	0.0 1.0 1.0
#pragma parameter HALO_NO_PREGAIN "        Pre-attenuate input signal gain to 1x"	0.0		0.0	1.0	1.0
#pragma parameter HALO_POWER      "        Strength (negative = 10x precision)"	0.9 	-50.0  5.0 0.01
#pragma parameter HALO_SHARPNESS  "        Sharpness"					3.00	0.05   7.0 0.05
#pragma parameter HALO_GAMMA      "        Gamma in, the higher, the less the halo on dark colors"	2.0 	1.0  10.0 0.05
#pragma parameter HALO_GAMMA_OUT  "        Gamma out"	 1.0	0.25  4.0 0.1
#pragma parameter HALO_VS_SCAN    "        Light up scanline gaps and dot grid gaps too"				0.0	0.0  1.0  0.01
#pragma parameter BLANK10 " " 0.0 0.0 1.0 1.0



// Bloom
#pragma parameter DO_BLOOM           "★ Bloom enable? (bl) ==>" 						0.0  0.0  1.0  1.0
#pragma parameter BLOOM_MIX          "        Final mix, (0.0=off)"					0.45 0.0 1.0  0.01
#pragma parameter BLOOM_SIZE         "        Radius"							4.0  0.25 30.0 0.25
#pragma parameter BLOOM_QUALITY      "        Quality: more is better but slower"			1.0  1.0 8.0 1.0
#pragma parameter BLOOM_GAMMA        "        Gamma in (threshold)"					8.0  1.0 10.0 0.5
#pragma parameter BLOOM_GAMMA_OUT    "        Gamma out (contour smoothness)"				1.0  0.1 10.0 0.1
#pragma parameter BLOOM_POWER        "        Power multiplier"						1.20  1.0 20.0 0.05  
#pragma parameter BLOOM_EYE_ADPT_SRT "        Modulate: Local exposure eye adaption strength"		0.45   0.0 10.0 0.05
#pragma parameter BLOOM_EYE_INERTIA  "        Modulate: Time before eye adaption starts"		1500  10.0 10000 50.0
#pragma parameter BLOOM_OVER_WHITE   "        Modulate: Strength on bright areas (0 = aura)"		0.5  0.0 1.0  0.05
#pragma parameter BLOOM_BYPASS       "        Bypass/Solo (1=Unmodulated, 2=Modulated)"			0.0  0.0 2.0  1.0
#pragma parameter BLANK13 " " 0.0 0.0 1.0 1.0



//Curvature parameters:
#pragma parameter DO_CURVATURE	     "★ Curvature/Border enable? (cu) ==>"			0.0   0.0 1.0 1.0
#pragma parameter GEOM_WARP_X        "        Warp X"				0.28   0.0 6.0 0.01
#pragma parameter GEOM_WARP_Y        "        Warp Y"				0.32   0.0 6.0 0.01
#pragma parameter GEOM_CUT_EARS      "        Cut curvature ears"	1.4   1.0 10.0 0.01
#pragma parameter GEOM_CORNER_SIZE   "        Corner radius"			0.005  0.005 0.1 0.001
#pragma parameter GEOM_CORNER_SMOOTH "        Corner sharpness"			350.0 15.0 1000.0 1.0
#pragma parameter BLANK14 " " 0.0 0.0 1.0 1.0



//Bezel related
#pragma parameter DO_BEZEL	      "★ Bezel enable? (be) ==>"				0.0   0.0 1.0 1.0
#pragma parameter BEZEL_USE_STRAIGHT  "        Straight"				0.0	0.0 1.0  1.0 
#pragma parameter BEZEL_INNER_ZOOM    "        Inner zoom (ignored if integer scaled)"	-0.18   -1.5 0.5 0.001
#pragma parameter BEZEL_FRAME_ZOOM    "        Frame zoom"				0.0   -1.5 0.5 0.001
#pragma parameter BEZEL_R             "        Color: Red"				-0.3   -1.0 1.0  0.005
#pragma parameter BEZEL_G             "        Color: Green"				-0.3   -1.0 1.0  0.005
#pragma parameter BEZEL_B             "        Color: Blue"				-0.3   -1.0 1.0  0.005
#pragma parameter BEZEL_CON           "        Contrast"				1.3   0.0  10.0 0.01
#pragma parameter BEZEL_RFL_ZOOM      "        Reflections zoom"			0.0   -1.5 0.5 0.005
#pragma parameter BEZEL_REFL_STRENGTH "        Reflections strength"			0.65    0.0 2.0 0.01
#pragma parameter BEZEL_RFL_BLR_SHD   "        Reflections sharpness"			-0.0  -0.5 1.0 0.01
#pragma parameter BEZEL_ROUGHNESS     "        Reflections roughness"			1.0    0.0 5.0 0.1
#pragma parameter BEZEL_DIFFUSION_STR "        Diffusion strength"             0.0     0.0 1.0 0.01
#pragma parameter BEZEL_SPCL_STRENGTH "        Specularity strength"			0.5    0.0 3.0 0.05
#pragma parameter BEZEL_CORNER_DARK   "        Darken corners"					0.8    0.0 1.0 0.05


#pragma parameter BLANK15 " " 0.0 0.0 1.0 1.0



//Background Image
#pragma parameter DO_BG_IMAGE	     "★ Back/Foreground image enable? (ba) ==>"				 0.0  0.0  1.0     1.0
#pragma parameter LABEL_WARNING1     "    ⚠ RetroArch aspect needs to be set to Full! ⚠"	 1.0  1.0  1.0     1.0
#pragma parameter BG_IMAGE_OVER	     "        Image over content (alpha channel driven)?"	 0.0  0.0  1.0     1.0
#pragma parameter BG_IMAGE_OFFX	     "        Shift Image over X axis"				 0.0  -1.0  1.0    0.0005
#pragma parameter BG_IMAGE_OFFY	     "        Shift Image over Y axis"				 0.0  -1.0  1.0    0.0005
#pragma parameter BG_IMAGE_ZOOM	     "        Zoom Image"					 1.0  -1.0  3.0    0.0005
#pragma parameter BG_IMAGE_ROTATION  "        Rotate image mode (-1 for auto)"	     		 -1.0  -1.0  2.0    1.0
#pragma parameter BG_IMAGE_NIGHTIFY  "        Nightify image"                                 0.0   0.0  1.0    0.1
#pragma parameter BG_IMAGE_WRAP_MODE "        Wrap mode: default, clamp to border, edge, repeat" 0.0  0.0    3.0    1.0
#pragma parameter BLANK16 " " 0.0 0.0 1.0 1.0

//Backdrop image
#pragma parameter DO_BACKDROP		"★ Backdrop mirrored image enable? ==>"		 0.0  0.0  1.0     1.0
#pragma parameter BACKDROP_OFFX		"        Shift backdrop over X axis"				 0.0  -1.0  1.0    0.0005
#pragma parameter BACKDROP_OFFY 	"        Shift backdrop over X axis"				 0.0  -1.0  1.0    0.0005
#pragma parameter BACKDROP_ZOOM 	"        Zoom backdrop"					 1.0  -1.0  3.0    0.0005
#pragma parameter BLANK161 " " 0.0 0.0 1.0 1.0


//Back leds
//Emulates leds under the monitor frame that slowly reacts to image contents
#pragma parameter DO_AMBILIGHT	            "★ Ambient light leds enable? (am) ==> "				1.0  0.0  1.0     1.0
#pragma parameter LABEL_WARNING3            "    ⚠ RetroArch aspect needs to be set to Full! ⚠"		1.0  1.0  1.0     1.0
#pragma parameter AMBI_STEPS	            "        Slowness"						60.0 5.0  1000.0  5.0
#pragma parameter AMBI_FALLOFF              "        Led power/falloff"			0.4  0.1  3.0     0.01
#pragma parameter AMBI_POWER                "        Led Saturation"						1.8  0.0  100.0     0.05
#pragma parameter AMBI_INT_OFFSET           "        Led internalness"              0.07 -1.0 1.0 0.01
#pragma parameter AMBI_STRETCH              "        Widen lights"						0.0  0.0  1.0     0.01
#pragma parameter AMBI_GAMMA                "        Output Gamma"						1.3  0.1  8.0     0.1
#pragma parameter AMBI_OVER_BEZEL           "        Colorize Bezel"					0.2  0.0  5.0     0.05
#pragma parameter AMBI_OVER_BEZEL_SIZE      "           . Colorization size"			0.15  0.0  0.5    0.001
#pragma parameter AMBI_BG_IMAGE_BLEND_MODE  "        Back/Foreground image alpha blend (0=mix, 1=add)"	0.0   0.0  1.0    1.0
#pragma parameter AMBI_ADD_ON_BLACK         "        Foggy (power on dark colors, add mode only)    "		1.0   0.0  1.0    0.05
#pragma parameter AMBI_BG_IMAGE_FORCE       "        Always colorize Back/Foreground image (add mode only) "		0.0   0.0  1.0    0.1
#pragma parameter BLANK17 " " 0.0 0.0 1.0 1.0



//Full screen glowing
//Modulate the image zooming depending on the image luminosity.
//You can lower the effect power through the DYNZOOM_FACTOR parameter.
#pragma parameter DO_DYNZOOM	     "★ Luminosity tied zoom (overrides integer scale)==>"		1.0   0.0   1.0  1.0
//Ditched and hardcoded to 80 in config.globals.inc.
	//#pragma parameter DYNZOOM_FACTOR     "        Narrowness"				80.0  15.0  120.0 0.5

#pragma parameter BLANK18 " " 0.0 0.0 1.0 1.0



//Vignette and spot
#pragma parameter DO_VIGNETTE	"★ Vignette enable? (vi) ==>"	0.0  0.0  1.0  1.0
#pragma parameter V_SIZE	"        Size"			0.7  0.3  2.0  0.02
#pragma parameter V_POWER	"        Power"			1.0  0.05 1.0  0.01

#pragma parameter DO_SPOT	"★ Spot enable? (sp) ==>"		0.0   0.0   1.0 1.0
#pragma parameter S_POSITION 	"        Position"		194.0   -420.0 378.0 1
#pragma parameter S_SIZE	"        Size"			0.4   0.0   1.0 0.01
#pragma parameter S_POWER	"        Power" 		0.1   0.05  2.0 0.01
#pragma parameter BLANK19 " " 0.0 0.0 1.0 1.0



//Global Zoom/Offset
#pragma parameter DO_GLOBAL_SHZO	 "★ Global shift/zoom enable? (zo) ==>"	0.0   0.0  1.0 	  1.0
#pragma parameter GLOBAL_OFFX	 "        X axis shift "			0.0  -1.0  1.0    0.0005
#pragma parameter GLOBAL_OFFY	 "        Y axis shift "			0.0  -1.0  1.0    0.0005
#pragma parameter GLOBAL_ZOOM	 "        Zoom"					2.0   0.0  3.0    0.0005
#pragma parameter BLANK21 " " 0.0 0.0 1.0 1.0



//Aspect Ratio
#pragma parameter label_ar	 "★ Aspect Ratio (as) "							0.0  0.0  0.0     1.0
#pragma parameter ASPECT_X       "        Aspect Ratio Numerator (<=0 for a preset)"   		0.0  -6.0 256. 1.0
#pragma parameter ASPECT_Y       "        Aspect Ratio Denominator"	  				3.0   0.0 256. 1.0
#pragma parameter BLANK22 " " 0.0 0.0 1.0 1.0
#pragma parameter label_aspect_presets "        Presets reference list:" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset0 "          (0 =  MAME 1.33)" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset1 "          (-1 = NTSC 1.5)" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset2 "          (-2 = PAL 1.25)" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset3 "          (-3 = Snes 8/7)" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset4 "          (-4 = Megadrive 10/7)" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset5 "          (-5 = Uncorrected)" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset6 "          (-6 = MAME rotated/TATE 0.75)" 0.0 0.0 0.0 1.0
#pragma parameter BLANK23 " " 0.0 0.0 1.0 1.0



//Content geomerty overrides
#pragma parameter DO_GAME_GEOM_OVERRIDE	  "★ Override content geometry enable? (ov)==>"	0.0   0.0  1.0 	  1.0
#pragma parameter GAME_GEOM_INT_SCALE     "        Integer scale (disables inner zoom) 2=No keep aspect"	0.0   0.0  2.0    1.0
#pragma parameter GAME_GEOM_INT_SCALE_MAX "        Maximum integer scale" 				10.0  1.0  100.0  1.0
#pragma parameter LABEL_WARNING4          "    ⚠ The following will override integer scale ⚠"	1.0  1.0  1.0     1.0
#pragma parameter GAME_GEOM_ASPECT	  "        Aspect (0 = unchanged)"		0.0    0.0  3.0	  0.005
#pragma parameter GAME_GEOM_VSHIFT	  "        Vertical position"			0.0   -10.0 10.0  0.01
#pragma parameter GAME_GEOM_HSHIFT	  "        Horizontal position"			0.0   -10.0 10.0  0.01
#pragma parameter GAME_GEOM_ZOOM	  "        Zoom"					1.0    0.0  2.0  0.01
#pragma parameter GAME_GEOM_OFF_FIX	  "        Sharp hack through offset (0.0=disable)"	0.0    0.0  100.0  1
#pragma parameter BLANK20 " " 0.0 0.0 1.0 1.0

//Tilt
#pragma parameter DO_TILT	  	"★ Tilt enable? (ti) ==>"				0.0   0.0  1.0 	  1.0
#pragma parameter TILT_X	  	"        Tilt along X axis"		0.0    -0.5  0.5  0.01
#pragma parameter TILT_Y	  	"        Tilt along Y axis"		0.0    -0.5  0.5  0.01
#pragma parameter TILT_FOV	  	"        Fov"					0.7    0.1	1.5   0.05
#pragma parameter TILT_BEZEL_K	"        Bezel multiplier"		1.0    0.0  1.5  0.01
#pragma parameter BLANK_01 " " 0.0 0.0 1.0 1.0

//Delta render
#pragma parameter label_alt_blank    "  !THE FOLLOWING FEATURES ARE STATIC, SEE docs-ng.md TO ENABLE"    0.0 0.0 0.0 1.0
#pragma parameter DELTA_RENDER_FORCE_REFRESH    "★ Delta render force refresh interval ? ==>"	4.0 1.0 3600.0 1.0
#pragma parameter DELTA_RENDER_CHECK_AREA       "        Delta render area size"			1.0 0.0 10.0 1.0
#pragma parameter BLANK_DR " " 0.0 0.0 1.0 1.0

// Alternative blanking, needs to be statically enabled, see docs.md.
#pragma parameter DO_ALT_BLANK       "★ Alternate line blanking enable? ==>"			0.0 0.0 1.0 1.0
#pragma parameter ALT_BLANK_STRENGTH "        Alternate black frame insertion strength" 	0.5 0.0 1.0 0.1
#pragma parameter ALT_BLANK_PERIOD   "        Blank lines period" 				4.0 1.0 30.0 1.0
#pragma parameter BLANK_02 " " 0.0 0.0 1.0 1.0


#pragma parameter SERVICE1 "Don't use me, for debug purposes only" 	0.5 0.0 1.0 0.01
//#pragma parameter SERVICE2 "Don't use me, for debug purposes only" 	0.5 -1.0 1.0 0.01
//#pragma parameter SERVICE3 "Don't use me, for debug purposes only" 	0.5 -1.0 1.0 0.01



#include "config.globals.inc"
