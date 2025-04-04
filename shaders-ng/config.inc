#include "../config/config-static.inc"

#define eps 1e-5
#define pi  3.141592653589793
#define TAU 6.28318530717958647693
#define alpha_mark 0.1

layout(push_constant) uniform Push {
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	vec4 avglum_passFeedbackSize;
	uint FrameCount;
	uint Rotation;
	float HALO_SHARPNESS ;
	float HALO_NO_PREGAIN;
	float HALO_POWER ;
	float HALO_GAMMA ;
	float HALO_GAMMA_OUT;
	float HALO_VS_SCAN ;
	float HALO_DO_MASK_HELPER;
	
	float DO_BLOOM ; //4
 	float BLOOM_QUALITY ; //1


} params;

layout(std140, set = 0, binding = 0) uniform UBO {
	mat4 MVP;
		float DO_CURVATURE;
	vec4 FinalViewportSize;
	vec4 final_passFeedbackSize;
	vec4 in_glow_passSize;
	vec4 placeholder;

	vec4 avglum_passSize;
	vec4 upscale_passSize;
	vec4 colortools_and_ntsc_passSize;
	vec4 colortools_and_ntsc_passFeedbackSize;

	float DO_IN_GLOW;

	float DO_HALO ;
	float DO_CCORRECTION;
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
	

	float DO_PPERSISTENCE;
	float PPERSISTENCE_START;
	float PPERSISTENCE_END;
	
	float GAMMA_OUT ;
	float SATURATION;
	float LUMINANCE;
	float VIBRANCE;
	float CONTRAST;
	float BRIGHTNESS;
	float TEMPERATURE;
	
	float DO_VIGNETTE;
	float V_SIZE;
	float V_POWER;
	
	float CLIP_TO_WHITE;
	

	float GEOM_WARP_X;
	float GEOM_WARP_Y;
	float GEOM_CORNER_SIZE;

	float ASPECT_X;
	float ASPECT_Y;
	
	float DO_SHIFT_RGB;
	float OFFSET_STRENGTH;
	
	float PIXELGRID_INTR_GAMMA_ADJ;

	float TATE;

	float DO_RF_NOISE;
	float RF_NOISE_SPARK;
	float RF_NOISE_STRENGTH;
	
	float MIN_LINES_INTERLACED;
	float DO_PIXELGRID;
	float PIXELGRID_OVERMASK;
	float DO_PIXELGRID_W;
	float DO_PIXELGRID_H;
	float PIXELGRID_COREY_FAKE_SCAN;
	float PIXELGRID_DOUBLESCAN;
	float PIXELGRID_MIN_H;
	float PIXELGRID_MIN_W;
	float PIXELGRID_MAX_H;
	float PIXELGRID_MAX_W;
	float PIXELGRID_SIZE_W;
	
	float IN_GLOW_SPREAD_SHARPNESS;

	float PIXELGRID_MUL_X;
													
	float PIXELGRID_OFFSET_CORE;
	float PIXELGRID_OFFSET_CORE_W;
	float PIXELGRID_NO_INTERBLEED_W;
	float PIXELGRID_NO_INTERBLEED_H;
	float PIXELGRID_H_DEDOT;
	
	float PIXELGRID_INTR_FLICK_MODE;
	float PIXELGRID_INTR_FLICK_POWR;
	float PIXELGRID_INTR_DISABLE_Y;
	float PIXELGRID_INTR_PAST_FIELD;
	
	float PIXELGRID_DECON_R_H;
	float PIXELGRID_DECON_G_H;
	float PIXELGRID_DECON_B_H;
	
	float PIXELGRID_Y_MASK;
	float PIXELGRID_Y_MASK_ON_WHITE;
	float PIXELGRID_Y_MASK_HEIGHT;
	float PIXELGRID_Y_MASK_OFFSET;
	float PIXELGRID_Y_MASK_OFFSET_DEHIVE;
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
	float PIXELGRID_DO_SHADOWMASK;
	float PIXELGRID_SHADOWMASK_H;
	float PIXELGRID_SHADOWMASK_SHIFT;
	
	float PIXELGRID_BASAL_GRID;
	
	float SERVICE1;
	
	float IN_GLOW_WARPSHARP_X;
	float IN_GLOW_WARPSHARP_Y;
	float IN_GLOW_WARPSHARP_GAMMA;
	
	float DO_TEST ;
	
	float COLOR_MONO_COLORIZE;
	float COLOR_MONO_HUE1;
	float COLOR_MONO_HUE2;
	float COLOR_MONO_HUE_BIAS;
	
	float DECON_RX;
	float DECON_RY;
	float DECON_GX;
	float DECON_GY;
	float DECON_BX;
	float DECON_BY;
	float EDGE_DEFOCUS;
	float EDGE_DEFOCUS_AREA_INV;
	float EDGE_DEFOCUS_DO_BLUR;
	
	float OriginalAspectRotated;


	float DO_GAME_GEOM_OVERRIDE;
	float GAME_GEOM_INT_SCALE;
	float GAME_GEOM_INT_SCALE_MAX;
	float GAME_GEOM_INT_SCALE_OVR;
	float GAME_GEOM_OFF_FIX;


	
	float OriginalFPS;
	uint FrameTimeDelta;
	

} global;


#pragma parameter LABEL0000 "Read the documentation in docs-ng.md text file" 		0.0 0.0 0.0 1.0
#pragma parameter LABEL0001 "==================================================" 		0.0 0.0 0.0 1.0
#pragma parameter DO_TEST "★ Show test pattern ==>" 		0.0 	0.0 12.0 1.0
#pragma parameter LABELTEST " " 		0.0 0.0 0.0 1.0


#pragma parameter IN_GLOW_GAMMA  "★ Gamma In"			2.0 	0.5 	10.0 0.01
#pragma parameter GAMMA_OUT      "★ Gamma out"			0.5		0.1 	5.0  0.01
#pragma parameter CLIP_TO_WHITE  "★ Clip to white (>1 = overclip)"		0.0		0.0 	2.0  0.05
#pragma parameter LABEL0054 " " 0.0 0.0 0.0 1.0


// Color correction 
#pragma parameter DO_CCORRECTION "★ Color corrections enable? (co) ==>" 		0.0 	0.0 1.0 1.0
#pragma parameter IN_GLOW_POWER  "       Input signal gain"					1.0 	0.0 5.0 0.05
#pragma parameter LUMINANCE      "       Luminance push (>1.0=clip)"		0.0	 0.0 1.5 0.05
#pragma parameter BRIGHTNESS     "       Brightness in   (0.0=off)"		0.0	-1.0 1.0 0.01
#pragma parameter CONTRAST       "       Contrast in     (0.0=off)"		0.0	-1.0 1.0 0.01
#pragma parameter TEMPERATURE    "       Temperature in (6500=off)"		6500.0	3000 14000.0 50.0
#pragma parameter COLOR_MONO_COLORIZE	"       Monochrome screen colorization"	0.0  0.0 1.0 0.1
#pragma parameter COLOR_MONO_HUE1       "          . Hue bright"					0.25 0.0 1.0 0.01
#pragma parameter COLOR_MONO_HUE2       "          . Hue dark"						0.3  0.0 1.0 0.01
#pragma parameter COLOR_MONO_HUE_BIAS   "          . Hue bright-dark bias"		0.0	-2.0 2.0 0.01
#pragma parameter SATURATION            "       Saturation in   (1.0=off)"		1.0	0.0  2.0 0.01
#pragma parameter VIBRANCE              "       Vibrance in   (0.0=off)"		0.0	0.0  5.0 0.01
#pragma parameter LABEL0003 " " 0.0 0.0 0.0 1.0


//Phosphor persistence
#pragma parameter DO_PPERSISTENCE       "★ Persistence of phosphors enable? (ppe) ==>"	0.0	 0.0 1.0 1.0
#pragma parameter PPERSISTENCE_START    "        Early decay"			0.9 	 0.0 1.0 0.05
#pragma parameter PPERSISTENCE_END      "        Late Persistence"		0.5 	 0.0 2.0 0.05
#pragma parameter LABEL0009 " " 0.0 0.0 0.0 1.0

//Deconvergence
#pragma parameter DO_SHIFT_RGB       "★ Deconvergence/Defocus enable? (de) ==>"	0.0	 0.0 1.0 1.0
#pragma parameter OFFSET_STRENGTH  "        Strength"			0.6 	 0.0 1.0 0.05
#pragma parameter DECON_RX         "        Red x offset"	    0.0 -50.0 50.0 0.25
#pragma parameter DECON_RY         "        Red y offset"	   -1.0 -50.0 50.0 0.25
#pragma parameter DECON_GX         "        Green x offset"		1.0 -50.0 50.0 0.25
#pragma parameter DECON_GY         "        Green y offset"		0.0 -50.0 50.0 0.25
#pragma parameter DECON_BX         "        Blue x offset"		0.0 -50.0 50.0 0.25
#pragma parameter DECON_BY         "        Blue y offset"		1.0 -50.0 50.0 0.25
#pragma parameter EDGE_DEFOCUS              "         . Deconvergence increases near edges (1=no increase)" 2.0 1.0 10.0 0.1
#pragma parameter EDGE_DEFOCUS_DO_BLUR      "         . Blur screen edges" 0.0 0.0 1.0 0.01
#pragma parameter EDGE_DEFOCUS_AREA_INV     "         . Focused Area" 0.4 0.0 0.5 0.01

#pragma parameter LABEL0010 " " 0.0 0.0 0.0 1.0

// RF Noise
#pragma parameter DO_RF_NOISE	 "★ RF Noise? (Post glow, Off, Pre glow)  ==>"			0.0 	-1.0  1.0     1.0
#pragma parameter RF_NOISE_STRENGTH "        Uniform noise"				0.05	0.0 1.0 0.01
#pragma parameter RF_NOISE_SPARK    "        Snow noise"				0.07		0.0 1.0 0.01
#pragma parameter LABEL0005 " " 0.0 0.0 0.0 1.0


// Input Blur / light glowing
#pragma parameter DO_IN_GLOW               "★ Glow/Blur enable? (gl) ==>"	 					0.0	0.0 1.0 1.0
#pragma parameter IN_GLOW_BIAS             "        Glow to blur bias"							1.0     0.0 1.0 0.1
#pragma parameter IN_GLOW_SPREAD           "        Glow light gain"		0.6 	0.0 4.0 0.05
#pragma parameter IN_GLOW_SPREAD_SHARPNESS "        Glow light sharpness"	2.0 	0.01 2.0 0.01
#pragma parameter IN_GLOW_W                "        Sharp X (neg=use BOX unsharp)"		2.5	-2.0 7.0 0.05
#pragma parameter IN_GLOW_H                "        Sharp Y (neg=use BOX unsharp)"		2.5	-2.0 7.0 0.05
#pragma parameter IN_GLOW_WARPSHARP_X      "        Warped glow (X)"               0.4  0.0 2.0 0.01
#pragma parameter IN_GLOW_WARPSHARP_Y      "        Warped glow (Y)"               0.4  0.0  2.0 0.01
#pragma parameter IN_GLOW_WARPSHARP_GAMMA  "        Warped glow dynamics (1.0=linear)"  1.0  0.01 1.0 0.01
#pragma parameter LABEL0011 " " 0.0 0.0 0.0 1.0

#pragma parameter TATE                     "★ Tate mode (0:disabled 1:auto 2:forced)"		1.0 	0.0 2.0 1.0
#pragma parameter LABEL0012 " " 0.0 0.0 0.0 1.0


#pragma parameter LABEL_INTERLACE           "★ Hi-resolution scanlines behaviour" 1.0 1.0 1.0 0.0
#pragma parameter MIN_LINES_INTERLACED      "    . Consider Hi-Resolution above # lines (0=never):"		380.0 	0.0 1024 1.0
#pragma parameter PIXELGRID_INTR_PAST_FIELD "    . Real interlacing (display previous field)"    0.0 0.0 1.0 0.1
#pragma parameter PIXELGRID_INTR_DISABLE_Y  "    . Hi-Res scanlines type (read docs):"           -1.0 -2.0 2.0 1.0
#pragma parameter LABEL0036                 "      (-2: Faker-Interlaced, -1: Fake-Interlaced)"          0.0 0.0 0.0 1.0
#pragma parameter LABEL0037                 "      ( 0: Interlaced, 1: No scanlines, 2: Don't interlace)" 0.0 0.0 0.0 1.0
#pragma parameter PIXELGRID_INTR_GAMMA_ADJ  "    . Interlaced brighness push (less is more, not for OLEDs)" 0.9 0.5 1.0 0.01
#pragma parameter PIXELGRID_INTR_FLICK_MODE "    . Scanlines flicker (0=off,1=on,2=if Hi-Res)"			2.0 	0.0 2.0 1.0
#pragma parameter PIXELGRID_INTR_FLICK_POWR "        . Flicker power"		  		0.20 	0.0 8.0 0.01

#pragma parameter LABEL0014 " " 0.0 0.0 0.0 1.0


// pixel Grid
#pragma parameter DO_PIXELGRID		 "★  Low level Phosphor grid enable? (ph) ==>"	0.0 0.0 1.0 1.0
#pragma parameter PIXELGRID_OVERMASK "      Overmask (1.0 = neutral)"	1.0 0.0 2.0 0.02
#pragma parameter LABEL0015 " " 0.0 0.0 0.0 1.0

#pragma parameter DO_PIXELGRID_H            "      ★ Scanlines (0 to disable)"    	1.0 0.0 1.25 0.05
#pragma parameter PIXELGRID_DOUBLESCAN      "         . Double-scan low input resolutions"  0.0 0.0 1.0 1.0
#pragma parameter PIXELGRID_COREY_FAKE_SCAN "         . Fake integer scanlines (-1=auto)"  -1.0 -1.0 1.0 1.0
#pragma parameter PIXELGRID_MIN_H	        "         . Phosphors height Min"           0.2 0.00 1.0 0.05
#pragma parameter PIXELGRID_MAX_H           "         . Phosphors height Max"           0.6 0.05 1.0 0.05

#pragma parameter PIXELGRID_GAMMA_H         "         . Phosphors height min->max gamma:"	4.2 1.0 8.00 0.1
#pragma parameter PIXELGRID_NO_INTERBLEED_H	  "         . Inter line extra steepness (1.0 to disable)"	1.0 1.0 11.0 0.1
#pragma parameter PIXELGRID_OFFSET_CORE       "         . Slotmask(fake) offset" 0.0 0.0 1.0 0.01
#pragma parameter PIXELGRID_OFFSET_CORE_W     "           . Slotmask(fake) width override (0=no override)"  0.0 0.0 4.0 1.0
#pragma parameter PIXELGRID_DECON_R_H         "         . Deconvergence Y: R phosphor" 0.0 -1.6 1.6 0.1
#pragma parameter PIXELGRID_DECON_G_H         "         . Deconvergence Y: G phosphor" 0.0 -1.6 1.6 0.1
#pragma parameter PIXELGRID_DECON_B_H       "         . Deconvergence Y: B phosphor" 0.0   -1.6 1.6 0.1
#pragma parameter PIXELGRID_H_DEDOT			"         . Dedot mask between scanlines (use only if needed!)"	0.0 0.0 2.0 0.1

#pragma parameter LABEL0016 " " 0.0 0.0 0.0 1.0


#pragma parameter DO_PIXELGRID_W     "    ★ Horizontal mask (0 to disable)"    	1.0 0.0 1.0 0.01
#pragma parameter PIXELGRID_SIZE_W   "       . Resolution: (core or screen)"	1.0 0.0 1.0 1.0
#pragma parameter PIXELGRID_MUL_X    "       . Cell size multiplier x (neg=divider):"	1.0 -8.0 8.0 0.125
#pragma parameter PIXELGRID_H_PRST   "       . Mask type preset (0: for manual)"  3.0 0.0 9.0 1.0
#pragma parameter LABEL0038          "         1:gm 2:gmx 3:rgb 4:rgbx 5:rbg 6:rbgx 7:wx 8:rgxb 9:wwx"  0.0 0.0 0.0 1.0
#pragma parameter PIXELGRID_H_COUNT  "           . 0: Phosphors+gap count (mask size)"	3.0 1.0 4.0  1.0
#pragma parameter PIXELGRID_R_SHIFT  "           . 0: R phospor position"      0.0  0.0 4.0 0.1
#pragma parameter PIXELGRID_G_SHIFT  "           . 0: G phospor position"      1.0  0.0 4.0 0.1
#pragma parameter PIXELGRID_B_SHIFT  "           . 0: B phospor position"      2.0  0.0 4.0 0.1
#pragma parameter PIXELGRID_MIN_W    "      . Phosphors width Min"			0.25 0.05 1.0 0.05
#pragma parameter PIXELGRID_MAX_W    "      . Phosphors width Max"			0.25 0.05 1.0 0.05
#pragma parameter PIXELGRID_GAMMA_W  "      . Phosphors width min->max gamma:"	4.2 1.0 8.00 0.1
#pragma parameter PIXELGRID_BASAL_GRID  "      . Black level of the unexcided phosphor grid"	0.0 0.0 10.0 0.01
#pragma parameter LABEL0017 " " 0.0 0.0 0.0 1.0

#pragma parameter PIXELGRID_Y_MASK               "      ★ Vertical cell Mask (aperturegrille/slotmask)"	0.5 0.0 1.0 0.05
#pragma parameter PIXELGRID_Y_MASK_COORDS        "           . Resolution: (core or screen)"	1.0 0.0 1.0 1.0
#pragma parameter PIXELGRID_Y_MASK_HEIGHT        "           . Height divider (neg = multiplier):"	0.5 -8.0 8.0 0.125
#pragma parameter PIXELGRID_Y_MASK_OFFSET        "           . Even/odd Y offset (slotmask)"	1.0 0.0 1.0 1.0
#pragma parameter PIXELGRID_Y_MASK_OFFSET_DEHIVE "           . Clears ''hives'' patterns (slotmask)"	0.00 0.00 4.0 0.1
#pragma parameter PIXELGRID_Y_MASK_SHIFT         "           . Vertical shift (neg = auto)"	-0.01 -0.01 1.0 0.01
#pragma parameter PIXELGRID_Y_MASK_STEEP         "           . Steepness"	2.0 1.0 30.0 1.0
#pragma parameter PIXELGRID_Y_MASK_ON_WHITE      "           . Fadeout under light"	0.5 0.0 2.0 0.01
#pragma parameter PIXELGRID_Y_SPARK              "           . Sparkling look punch"	0.0 0.0 8.0 0.1

#pragma parameter LABEL0018 " " 0.0 0.0 0.0 1.0

#pragma parameter PIXELGRID_DO_SHADOWMASK    "      ★ Shadowmask "	0.0 0.0 1.0 1.0
#pragma parameter label_shadowmask           "       !! Please, ensure that horizontal mask" 0.0 0.0 0.0 1.0
#pragma parameter label_shadowmask2          "       !! phosphor width is not too low." 0.0 0.0 0.0 1.0
#pragma parameter PIXELGRID_SHADOWMASK_SHIFT "           . X staggering    "	1.0 0.5 4.0 0.5
#pragma parameter PIXELGRID_SHADOWMASK_H     "           . Phosphor height "	1.0 1.0 10.0 1.0
#pragma parameter LABEL0019 " " 0.0 0.0 0.0 1.0


// Halo
#pragma parameter DO_HALO             "★ Halo or Mask helper enable? (ha) ==>" 						0.0	0.0 1.0 1.0
#pragma parameter HALO_NO_PREGAIN     "     Halo: Pre-attenuate input signal gain to 1x"	0.0		0.0	1.0	1.0
#pragma parameter HALO_POWER          "     Halo: Strength (negative = 10x precision)"	0.9 	-50.0  5.0 0.01
#pragma parameter HALO_SHARPNESS      "     Halo: Sharpness"					3.00	0.05   7.0 0.05
#pragma parameter HALO_GAMMA          "     Halo: Gamma in: Higher -> less halo on dark colors"	2.0 	1.0  10.0 0.05
#pragma parameter HALO_GAMMA_OUT      "     Halo: Gamma out"	 1.0	0.25  4.0 0.05
#pragma parameter HALO_DO_MASK_HELPER "     Mask helper: Additional brighness if horizontal mask clips" 	0.0	0.0 1.0 0.05 
#pragma parameter LABEL_HALO_HELP     "         (Mask helper: read docs-ng.md for help)" 	0.0 0.0 0.0 1.0
#pragma parameter HALO_VS_SCAN        "     Both: Light scanlines and dot grid gaps"				0.0	0.0  1.0  0.01
#pragma parameter LABEL0021 " " 0.0 0.0 0.0 1.0


// Bloom
#pragma parameter DO_BLOOM           "★ Bloom enable? (bl) ==>" 						0.0  0.0  1.0  1.0
#pragma parameter BLOOM_MIX          "        Final mix, (0.0=off)"					0.45 0.0 1.0  0.01
#pragma parameter BLOOM_SIZE         "        Radius"							4.0  0.25 30.0 0.25
#pragma parameter BLOOM_QUALITY      "        Quality: more is better but slower"			1.0  1.0 8.0 1.0
#pragma parameter BLOOM_GAMMA        "        Gamma in (threshold)"					8.0  1.0 10.0 0.5
#pragma parameter BLOOM_GAMMA_OUT    "        Gamma out (contour smoothness)"				1.0  0.1 10.0 0.1
#pragma parameter BLOOM_POWER        "        Power multiplier"						1.5  0.5 20.0 0.05  
#pragma parameter BLOOM_EYE_ADPT_SRT "        Modulate: Local exposure eye adaption strength"		0.45   0.0 10.0 0.05
#pragma parameter BLOOM_EYE_INERTIA  "        Modulate: Time before eye adaption starts"		1500  10.0 10000 50.0
#pragma parameter BLOOM_OVER_WHITE   "        Modulate: Strength on bright areas (0 = aura)"		0.5  0.0 1.0  0.05
#pragma parameter BLOOM_BYPASS       "        Bypass/Solo (1=Unmodulated, 2=Modulated)"			0.0  0.0 2.0  1.0
#pragma parameter LABEL0022 " " 0.0 0.0 0.0 1.0



//Curvature parameters:
#pragma parameter DO_CURVATURE	     "★ Curvature/Corners/Edges enable? (cu) ==>"			0.0   0.0 1.0 1.0
#pragma parameter GEOM_WARP_X        "        Warp X"				0.28   0.0 6.0 0.01
#pragma parameter GEOM_WARP_Y        "        Warp Y"				0.32   0.0 6.0 0.01
#pragma parameter GEOM_CORNER_SIZE   "        Corners radius"			0.008 0.002 0.1 0.001
#pragma parameter LABEL0023 " " 0.0 0.0 0.0 1.0



//Vignette and spot
#pragma parameter DO_VIGNETTE	"★ Vignette enable? (vi) ==>"	0.0  0.0  1.0  1.0
#pragma parameter V_SIZE	"        Size"			0.7  0.3  2.0  0.02
#pragma parameter V_POWER	"        Power"			1.0  0.05 1.0  0.01


//Aspect Ratio
#pragma parameter label_ar	 "★ Aspect (applies to game and bezel) "							1.0  1.0  1.0     0.0
#pragma parameter ASPECT_X   "       Aspect Ratio Numerator (<=0 for a preset)"   		0.0  -9.0 256. 1.0
#pragma parameter ASPECT_Y   "       Aspect Ratio Denominator"	  				3.0   0.0 256. 1.0
//#pragma parameter LABEL0042 " " 0.0 0.0 0.0 1.0 
#pragma parameter LABEL0043  "       Presets:" 0.0 0.0 0.0 1.0
#pragma parameter LABEL0044  "       -0=Mame:4/3 -1=NTSC:1.5 -2=PAL:1.25 -3=SNES:8/7" 0.0 0.0 0.0 1.0
#pragma parameter LABEL0045  "       -4=Megadrive:10/7 -5=Uncorrected -6=Mame Rotated:3/4" 0.0 0.0 0.0 1.0
#pragma parameter LABEL0047  "       -7=Core provided (auto off) -8=Core provided (always on)" 0.0 0.0 0.0 1.0
#pragma parameter LABEL0048  "       -9=Stretch to window" 0.0 0.0 0.0 1.0
#pragma parameter LABEL0051 " " 0.0 0.0 0.0 1.0


//Game geomerty overrides
#pragma parameter DO_GAME_GEOM_OVERRIDE	  "★ Override game geometry enable? (ov)==>"	0.0   0.0  1.0 	  1.0
#pragma parameter GAME_GEOM_INT_SCALE     "        Integer scale (2=No keep aspect)"	0.0   0.0  2.0    1.0
#pragma parameter GAME_GEOM_INT_SCALE_MAX "        .    Maximum integer scale" 			10.0  1.0  100.0  1.0
#pragma parameter GAME_GEOM_INT_SCALE_OVR "        .    Permit integer overscale by" 			1.04   1.00  1.15  0.01
#pragma parameter GAME_GEOM_OFF_FIX	      "        .    Sharp hack through offset (0.0=disable)"	0.0    0.0  100.0  1
#pragma parameter LABEL0034 " " 0.0 0.0 0.0 1.0

#pragma parameter SERVICE1 "Don't use me, for debug purposes only" 	0.0 -5.0 5.0 0.01

// User parameters goes here, they overrides almost everything:
// Retroarch releases past October 2024 (v1.17) support this:
#pragma include_optional "../config/config-user-optional.txt"

// Deprecated on Jan, 25, 2025 in favour of config-user-optional.txt
// We still support config-user.txt in old retroarch versions.
// We test for non include_optional support by querying _HAS_FRAMETIME_UNIFORMS that was merged
// a month after  include_optional support (Oct 21, 2024 |-> Nov 13, 2024)
#ifndef _HAS_FRAMETIME_UNIFORMS
#include "../config/config-user.txt" //Don't indent this!
#endif

// The following translates global.PARAMETER to PARAMETER
#include "config.globals.inc"
