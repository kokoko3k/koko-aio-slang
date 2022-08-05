#define GLOW_SHARP_MAX 15 		//This has to be the same as the max used for in_glow_wh
#define MIN_LINES_INTERLACED 300	//Consider content interlaced if lines are more than this
//#define in_aspect (1.23)
#define in_aspect (1.33)
#define noisepower 0.015


layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	vec4 final_passSize;
	uint FrameCount;

	float SCANLINE_DARK;
	float VMASK_OVERWHITE ;
	float DRKLN_OVERWHITE ;
	float DO_DARKLINES_VOFFSET ;
	float DARKLINES_PERIOD ;
	float halo_w ;
	float halo_h ;
	float halo_power ;
	float halo_gamma ;
	float DO_BLOOM ; //4
 	float bloom_quality ; //1
	float prefer_std_pow; 
} params;

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
	float DO_SCANLINES;
	float DO_IN_GLOW;
	float DO_RGB_MASK ;
	float DO_DARKLINES ;
	float DO_HALO ;
	float DO_CCORRECTION;
	float DO_ALT_BLANK;
	float IN_GLOW_ADD ;
	float in_glow_wh ;
	float in_glow_power ;
	float in_glow_gamma ;
	float BLOOM_MIX;
 	float bloom_size ; //1
	float bloom_gamma; //1
	float bloom_on_dark_only; //1
	float bloom_power; //1
  	float bloom_gamma_out; 
  	float ALT_BLANK_STRENGTH ; //2 FIXME to 1
	float DO_FXAA ; //1
	float scanline_flickering ; //2
	float scanline_disable_on_interlace;
	float RGB_MASK_STRENGTH;
	float DARKLINES_STRENGTH;
	float GAMMA_OUT ; //1
	float saturation ; //1
	
	float DO_CURVATURE;
	float SHARPNESS_H;
	float SHARPNESS_V;
	float GEOM_CURVATURE;
	float GEOM_WARP_X;
	float GEOM_WARP_Y;
	float GEOM_CORNER_SIZE;
	float GEOM_CORNER_SMOOTH;

	float DO_SPOT;
	float s_center_x;
	float s_center_y; 
	float s_size;
	float s_power;
	float s_bypass;

	float DO_VIGNETTE;
	float v_noisepower;
	float v_size;
	float v_power;
	float v_bypass;
	
} global;



// PARAMETERS AND MEANING



//Misc
//Depending on the compiler and exponent size, one may prefer to use the standard pow or the
//integer optimized one. The optimize version will use only integer values.
#pragma parameter str_1          "Optimizations: see which is faster" 								0.0 	0.0 1.0 1.0
#pragma parameter prefer_std_pow "       Use pow (choose fractional gamma too for halo and glow)"				0.0 	0.0 1.0 1.0

                                                                                        

// FXAA
// Apply an antialiasing filter via FXAA from Nvidia.
#pragma parameter DO_FXAA "FXAA:"	1.0 	0.0 1.0 1.0


// Scanlines
// Blank even source lines, the value from 0.0 to 1.0 expresses the darkness of the blanked lines
// 1.0 means no blank at all.

#pragma parameter DO_SCANLINES	"Scanlines:"									1.0 	0.0 1.0 1.0
#pragma parameter SCANLINE_DARK "        Scanlines gap brightness"			  			0.0 	0.0 1.0 0.05

// Alternate the drawing of the scanlines between frames. this will produce a flickering typical of
// interlaced screens; 0 disable the effect, 1 always enables it, 2 enables it only when
// the shader detects an interlaced signal, which actually means that the vertical resoution is "high enough"
#pragma parameter scanline_flickering "        Interlace Flicker (0=off,1=on,2=if interlaced)"		  	2.0 	0.0 2.0 1.0

#pragma parameter scanline_disable_on_interlace "        Disable on interlaced screen"			  	0.0 	0.0 1.0 1.0



// Input glowing
// Emulates the glowing of the input signal by blurring it with "in_glow_wh" sharpness.
// The blur always affects horizontal sharpness, vertical sharpness is affected only if Dark scanline brightness is < 1.0.
// Apply a gamma filter "in_glow_gamma" to "light" it, multiplying the result by "in_glow_power" and
// finally interpolating(*) it with the source image.
// "IN_GLOW_ADD" allows to modulate from interpolation(*) to a sum, wihch may (or not) produce better effects.
// With "IN_GLOW_ADD=0" input glowing does not alter the RGB mask
// or slot mask applied to the image.
#pragma parameter DO_IN_GLOW    "Input power/glowing:"	 					1.0	0.0 1.0 1.0
#pragma parameter in_glow_power "        Input signal glow strength"				0.45 	0.0 10.0 0.05
#pragma parameter in_glow_wh    "        Sharpness"						2.5	0.0 15.0 0.05
#pragma parameter in_glow_gamma "        Gamma, the higher, the less the glow on dark colors"	1.0 	1.0 10.0 0.1
#pragma parameter IN_GLOW_ADD   "        Overflows from the scanlines, sharper image"		0.0 	0.0 1.0 0.05



// RGB Mask
// Emulates CRT RGB phosphors.
// This is done by multiplying the source image pixels, in turn, by red green or blue.
// The strenght of the multiplication, and so of the final effect is affected by "RGB_MASK_STRENGTH" value.
// A Value of 0 completely disable the effect.
// "VMASK_OVERWHITE" modulates the strenght of the effect depending on the source pixel brightness,
// This is handy  if you want to keep a good image contrast/brightness, but keep in mind that other
// parameters like haloing and bloom.
#pragma parameter DO_RGB_MASK        "RGB Mask:"         				1.0 	0.0 1.0 1.0
#pragma parameter RGB_MASK_STRENGTH  "        Strength (0.0=off)"			0.75  	0.0 1.0 0.05
#pragma parameter VMASK_OVERWHITE    "        How much to affect bright colors"	1.0 	0.0 1.0 0.05



// Aperture grille/slot mask (shadow mask not implemented)
// Draw darklines on screen coordinates, by mixing black pixels with the source image
// on final viewport coordinates.
// "DARKLINES_STRENGTH" expresses the final strenght of the effect.
// if "DO_DARKLINES_VOFFSET" is 0, straight horizontal black lines will be painted that emulates an aperture grille.
// "DARKLINES_PERIOD" expresses every how many lines draw a black one.
// "DO_DARKLINES_VOFFSET" lets you to vertically offset by ""DARKLINES_PERIOD/2" the lines every 3 screen pixels,
// allowing, in conjunction with RGB mask, to emulate slot mask
#pragma parameter DO_DARKLINES          "Slotmask/Aperture grille"			0.0 	0.0 1.0 1.0
#pragma parameter DARKLINES_STRENGTH    "        Strength"				0.3 	0.0 1.0 0.05
#pragma parameter DO_DARKLINES_VOFFSET  "        Offset by triads"			1.0 	0.0 1.0 1.0
#pragma parameter DARKLINES_PERIOD      "        Period"				4.0 	-8.0 8.0 2.0
#pragma parameter DRKLN_OVERWHITE       "        How much to affect bright colors"	1.0 	0.0 1.0 0.05



// Halo
// The parameters are the same as input glowing, but this time the effect is applie
// after emulating the RGB phosphors the aperture grille or the slot masks and, instead of
// multiplying the resulting picture by the source one, it is added.
// this means that haloing will produce solid colors,
// lessening afromentioned effects on bright colors.
#pragma parameter DO_HALO       "Halo:" 							1.0	0.0 1.0 1.0
#pragma parameter halo_power    "        Strength (neg=off)"					0.9 	-0.05 10.0 0.05
#pragma parameter halo_w        "        Horizontal sharpness"					1.75	0.0  15.0 0.05
#pragma parameter halo_h        "        Vertical sharpness"					1.75	0.0  15.0 0.05
#pragma parameter halo_gamma    "        Gamma, the higher, the less the halo on dark colors"	2.0 	1.0  10.0 0.1



// Bloom
// The image is downsampled, bloomed and mixed back with the original image.
// "BLOOM_MIX" is the final mix strength
// "bloom_size" is the radius of the blurred image
// "bloom_quality" express a tradeoff between quality and effect speed.
// "bloom_gamma" allows to apply more bloom on the bright colors of the source image
// "bloom_power" is the additional gain applied to the bloom
// "bloom_on_dark_only" will mix the bloomed image with the original depending on the brightness of
// the original image.
#pragma parameter DO_BLOOM           "Bloom:" 				                0.0  0.0  1.0  1.0
#pragma parameter BLOOM_MIX          "        Final mix, (0.0=off)"			0.15 0.0 1.0  0.01
#pragma parameter bloom_size         "        Radius"					4.0  0.5 30.0 0.5
#pragma parameter bloom_quality      "        Quality: more is better but slower"	8.0  2.0 32.0 1.0
#pragma parameter bloom_gamma        "        Input Gamma"				2.0  1.0 10.0 1.0
#pragma parameter bloom_power        "        Power multiplier"				2.0  1.0 10.0 0.1
#pragma parameter bloom_gamma_out    "        Output Gamma"				1.0  0.1 10.0 0.05
#pragma parameter bloom_on_dark_only "        Apply less over bright areas"		1.0  0.0 1.0  1.0



// Gamma and saturation correction
// Correct the final gamma of the image
// To have more or less saturated colors use "saturation" > 1 or "saturation" < 1
#pragma parameter DO_CCORRECTION "Color corrections:" 			0.0 0.0 1.0 1.0
#pragma parameter GAMMA_OUT      "        Gamma output"			0.69	0.1 9.0  0.025
#pragma parameter saturation     "        Saturation modifier (1.0=off)"	1.0	0.0 10.0 0.025


//Curvature parameters:
#pragma parameter DO_CURVATURE	     "Emulate curvature:"			1.0   0.0 1.0 1.0
#pragma parameter GEOM_CURVATURE     "        Curvature"			0.02  0.0 0.1 0.01
#pragma parameter GEOM_WARP_X        "        Warp X"				0.0   0.0 0.1 0.01
#pragma parameter GEOM_WARP_Y        "        Warp Y"				0.03  0.0 0.1 0.01
#pragma parameter GEOM_CORNER_SIZE   "        Corner Size"			0.01  0.0 0.1 0.005
#pragma parameter GEOM_CORNER_SMOOTH "        Corner sharpness"			350.0 50.0 1000.0 25.0
#pragma parameter SHARPNESS_H        "        Sharpness Horizontal"		0.6   0.0 1.0 0.05
#pragma parameter SHARPNESS_V        "        Sharpness Vertical"		1.0   0.0 1.0 0.05


//Vignette and spot

#pragma parameter DO_VIGNETTE	"Emulate vignette effect:"	1.0  0.0  1.0  1.0
#pragma parameter v_bypass	"    bypass "	        	0.0  0.0  1.0  1.0
#pragma parameter v_size	"        size"			12   0.1  10   0.05
#pragma parameter v_power	"        power"			0.8  0.05 2.0  0.05

#pragma parameter DO_SPOT	"Emulate spot effect:"	1.0   0.0   1.0 1.0
#pragma parameter s_bypass	"    bypass"	        0.0   0.0   1.0 1.0
#pragma parameter s_center_x 	"    x position"		-0.4  -1.5  1.5 0.05
#pragma parameter s_center_y	"    y postion "		0.4   -1.5  1.5 0.05
#pragma parameter s_size	"    size"			0.15  0.01   10  0.01
#pragma parameter s_power	"    power" 			0.25  0.05  2.0 0.05









// Alternative blanking.
// Emulates the low pixel persistance of CRT monitors and reduces the motion blur,
// typical of LCD displays, by blanking even/odd screen lines on even/odd frames.
// ALT_BLANK_STRENGTH expresses the strength of the "blank".
#pragma parameter DO_ALT_BLANK       "Alternate blanking: " 					0.0 0.0 1.0 1.0
#pragma parameter ALT_BLANK_STRENGTH "        Alternate black frame insertion strength" 	0.0 0.0 1.0 0.1


#define DO_FXAA        global.DO_FXAA
#define prefer_std_pow params.prefer_std_pow

#define DO_SCANLINES                  global.DO_SCANLINES
#define SCANLINE_DARK                 params.SCANLINE_DARK
#define SCANLINE_OVERWHITE            global.SCANLINE_OVERWHITE
#define scanline_flickering           global.scanline_flickering
#define scanline_disable_on_interlace global.scanline_disable_on_interlace

#define DO_IN_GLOW   global.DO_IN_GLOW
#define IN_GLOW_ADD   global.IN_GLOW_ADD
#define in_glow_wh    global.in_glow_wh
#define in_glow_power global.in_glow_power
#define in_glow_gamma global.in_glow_gamma

#define DO_RGB_MASK       global.DO_RGB_MASK
#define RGB_MASK_STRENGTH global.RGB_MASK_STRENGTH
#define VMASK_OVERWHITE   params.VMASK_OVERWHITE

#define DO_DARKLINES         global.DO_DARKLINES
#define DARKLINES_STRENGTH   global.DARKLINES_STRENGTH
#define DRKLN_OVERWHITE      params.DRKLN_OVERWHITE
#define DO_DARKLINES_VOFFSET params.DO_DARKLINES_VOFFSET
#define DARKLINES_PERIOD     params.DARKLINES_PERIOD

#define DO_HALO    global.DO_HALO
#define halo_w     params.halo_w
#define halo_h     params.halo_h
#define halo_power params.halo_power
#define halo_gamma params.halo_gamma

#define DO_BLOOM           params.DO_BLOOM
#define BLOOM_MIX          global.BLOOM_MIX
#define bloom_quality      params.bloom_quality
#define bloom_size         global.bloom_size
#define bloom_gamma        global.bloom_gamma
#define bloom_power        global.bloom_power
#define bloom_gamma_out    global.bloom_gamma_out
#define bloom_on_dark_only global.bloom_on_dark_only

#define DO_CCORRECTION global.DO_CCORRECTION
#define GAMMA_OUT      global.GAMMA_OUT
#define saturation     global.saturation

#define DO_ALT_BLANK       global.DO_ALT_BLANK
#define ALT_BLANK_STRENGTH global.ALT_BLANK_STRENGTH


#define DO_CURVATURE global.DO_CURVATURE
#define SHARPNESS_H        global.SHARPNESS_H
#define SHARPNESS_V        global.SHARPNESS_V
#define GEOM_CURVATURE     global.GEOM_CURVATURE
#define GEOM_WARP_X        global.GEOM_WARP_X
#define GEOM_WARP_Y        global.GEOM_WARP_Y
#define GEOM_CORNER_SIZE   global.GEOM_CORNER_SIZE
#define GEOM_CORNER_SMOOTH global.GEOM_CORNER_SMOOTH


#define DO_SPOT    global.DO_SPOT
#define s_bypass   global.s_bypass
#define s_center_x global.s_center_x
#define s_center_y global.s_center_y
#define s_size     global.s_size
#define s_power    global.s_power


#define DO_VIGNETTE  global.DO_VIGNETTE
#define v_bypass     global.v_bypass
#define v_noisepower global.v_noisepower
#define v_size       global.v_size
#define v_power      global.v_power







