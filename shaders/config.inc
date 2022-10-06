	//Setting the glow/halo sharpness parameter to this
	//will skip the blurring phase and lowers the gpu use
	//Set this to the same value as used for the maximum
	//of IN_GLOW_WH, HALO_W and HALO_H
#define GLOW_SHARP_MAX 6	        

	//Consider content interlaced if lines are more than this
#define MIN_LINES_INTERLACED 300

//Sort of dithering used in vignette, spot, backlight leds
	#define NOISEPOWER ((params.OutputSize.z)*3)

	//Bezel reflection area size in relation to the game frame
	//Use the lowest possible value for best performance
#define BEZEL_REFLECTION_AREA_SIZE 0.1;

	// 0.0-1.0: sensitivity to scene change (ambilike stuff), 0.0 changes more
#define AMBI_SCENE_CHG_THRSHLD 0.07  
	
	// The following will allow to sample at reduced interval
	// The scene change detection logic will take advantage of it
	// So that quick fades will still be treated as scene changes
#define AMBI_AVGLUM_DIVIDER 4

	// The following defines the speed of the color fades 
	// when changing scene. (range 0..1)
	// It is wise to correlate it with avglum_divider
	// try between (1/avglum_divider) and (1/avglum_divider)/3
#define AMBI_FAST_STEP 0.125 



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
	float HALO_W ;
	float HALO_H ;
	float HALO_POWER ;
	float HALO_GAMMA ;
	float DO_BLOOM ; //4
 	float BLOOM_QUALITY ; //1

} params;

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
	
	vec4 FinalViewportSize;
	vec4 in_glow_and_scanline_flickering_passSize;
	vec4 FXAA_passSize;
	vec4 main_passSize;
	vec4 monitor_bodySize;
	vec4 first_passSize;
	
	float DO_SCANLINES;
	float DO_IN_GLOW;
	float DO_RGB_MASK ;
	float DO_DARKLINES ;
	float DO_HALO ;
	float DO_CCORRECTION;
	float DO_ALT_BLANK;
	float IN_GLOW_ADD ;
	float GLOW_OVER_DARK_SCANLINES ;
	float IN_GLOW_WH ;
	float IN_GLOW_POWER ;
	float IN_GLOW_GAMMA ;
	float BLOOM_MIX;
 	float BLOOM_SIZE ; //1
	float BLOOM_GAMMA; //1
	float BLOOM_BYPASS; //1
	float BLOOM_POWER; //1
  	float BLOOM_GAMMA_out; 
  	float ALT_BLANK_STRENGTH ; //2 FIXME to 1
  	float ALT_BLANK_PERIOD ;
	float DO_FXAA ; //1
	float SCANLINE_FLICKERING ; //2
	float SCANLINE_DISABLE_ON_INTERLACE;
	float RGB_MASK_STRENGTH;
	float DARKLINES_STRENGTH;
	float GAMMA_OUT ; //1
	float SATURATION ; //1
	
	float DO_CURVATURE;

	float GEOM_WARP_X;
	float GEOM_WARP_Y;
	float GEOM_CORNER_SIZE;
	float GEOM_CORNER_SMOOTH;

	float DO_BEZEL;
	float BEZEL_R;
	float BEZEL_G;
	float BEZEL_B;
	float BEZEL_CON;
	float BEZEL_INNER_ZOOM;
	float BEZEL_IMAGE_BORDER;
	float BEZEL_FRAME_ZOOM;

	float DO_SPOT;
	float S_CENTER_X;
	float S_CENTER_Y; 
	float S_SIZE;
	float S_POWER;
	float S_BYPASS;

	float DO_VIGNETTE;
	float V_SIZE;
	float V_POWER;
	float V_BYPASS;

	float DO_DYNZOOM;
	float DYNZOOM_FACTOR;
	
	float DO_AMBILIGHT;
	float AMBI_FALLOFF;
	float AMBI_POWER;
	float ASPECT_X;
	float ASPECT_Y;
	float AMBI_STEPS;
} global;



// PARAMETERS AND MEANING                                                    

// FXAA
// Apply an antialiasing filter via FXAA from Nvidia.
#pragma parameter DO_FXAA "★ FXAA:"	1.0 	0.0 1.0 1.0


// Scanlines
// Blank even source lines, the value from 0.0 to 1.0 expresses the darkness of the blanked lines
// 1.0 means no blank at all.

#pragma parameter DO_SCANLINES	"★ Scanlines:"									1.0 	0.0  1.0 1.0
#pragma parameter SCANLINE_DARK "        Scanlines gap brightness"			  			0.0 	-1.0 1.0 0.05

// Alternate the drawing of the scanlines between frames. this will produce a flickering typical of
// interlaced screens; 0 disable the effect, 1 always enables it, 2 enables it only when
// the shader detects an interlaced signal, which actually means that the vertical resoution is "high enough"
#pragma parameter SCANLINE_FLICKERING "        Interlace Flicker (0=off,1=on,2=if interlaced)"		  	2.0 	0.0 2.0 1.0

#pragma parameter SCANLINE_DISABLE_ON_INTERLACE "        Disable on interlaced screen"			  	0.0 	0.0 1.0 1.0



// Input glowing
// Emulates the glowing of the input signal by blurring it with "IN_GLOW_WH" sharpness.
// The blur always affects horizontal sharpness, vertical sharpness is affected only if Dark scanline brightness is < 1.0.
// Apply a gamma filter "IN_GLOW_GAMMA" to "light" it, multiplying the result by "IN_GLOW_POWER" and
// finally interpolating(*) it with the source image.
// "IN_GLOW_ADD" allows to modulate from interpolation(*) to a sum, wihch may (or not) produce better effects.
// With "IN_GLOW_ADD=0" input glowing does not alter the RGB mask
// or slot mask applied to the image.
#pragma parameter DO_IN_GLOW               "★ Input power/glowing:"	 					1.0	0.0 1.0 1.0
#pragma parameter IN_GLOW_POWER            "        Input signal glow strength"					0.45 	0.0 5.0 0.05
#pragma parameter IN_GLOW_WH               "        Sharpness"							2.5	0.2 6.0 0.05
#pragma parameter IN_GLOW_GAMMA            "        Gamma, the higher, the less the glow on dark colors"	1.0 	1.0 10.0 0.1
#pragma parameter IN_GLOW_ADD              "        Post gain (0.0 to disable)"					0.0 	0.0 1.0 0.05
#pragma parameter GLOW_OVER_DARK_SCANLINES "        Scanlines bleeding"						1.0 	0.0 3.0 0.1


// RGB Mask
// Emulates CRT RGB phosphors.
// This is done by multiplying the source image pixels, in turn, by red green or blue.
// The strenght of the multiplication, and so of the final effect is affected by "RGB_MASK_STRENGTH" value.
// A Value of 0 completely disable the effect.
// "VMASK_OVERWHITE" modulates the strenght of the effect depending on the source pixel brightness,
// This is handy  if you want to keep a good image contrast/brightness, but keep in mind that other
// parameters like haloing and bloom.
#pragma parameter DO_RGB_MASK        "★  RGB Mask:"         				1.0 	0.0 1.0 1.0
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
#pragma parameter DO_DARKLINES          "★ Slotmask/Aperture grille"		0.0 	0.0 1.0 1.0
#pragma parameter DARKLINES_STRENGTH    "        Strength"				0.3 0.0 1.0 0.05
#pragma parameter DO_DARKLINES_VOFFSET  "        Offset by triads"		1.0 	0.0 1.0 1.0
#pragma parameter DARKLINES_PERIOD      "        Period"				4.0 -8.0 8.0 2.0
#pragma parameter DRKLN_OVERWHITE       "        How much to affect bright colors"	1.0 0.0 1.0 0.05



// Halo
// The parameters are the same as input glowing, but this time the effect is applie
// after emulating the RGB phosphors the aperture grille or the slot masks and, instead of
// multiplying the resulting picture by the source one, it is added.
// this means that haloing will produce solid colors,
// lessening afromentioned effects on bright colors.
#pragma parameter DO_HALO       "★ Halo:" 							1.0	0.0 1.0 1.0
#pragma parameter HALO_POWER    "        Strength"						0.9 	0.0  5.0 0.05
#pragma parameter HALO_W        "        Horizontal sharpness"					1.75	0.2  6.0 0.05
#pragma parameter HALO_H        "        Vertical sharpness"					1.75	0.2  6.0 0.05
#pragma parameter HALO_GAMMA    "        Gamma, the higher, the less the halo on dark colors"	2.0 	1.0  10.0 0.1



// Bloom
// The image is downsampled, bloomed and mixed back with the original image.
// "BLOOM_MIX" is the final mix strength
// "BLOOM_SIZE" is the radius of the blurred image
// "BLOOM_QUALITY" express a tradeoff between quality and effect speed.
// "BLOOM_GAMMA" allows to apply more bloom on the bright colors of the source image
// "BLOOM_POWER" is the additional gain applied to the bloom
// "BLOOM_BYPASS" will show only the bloomed component
// the original image.
#pragma parameter DO_BLOOM           "★ Bloom:" 				        0.0  0.0  1.0  1.0
#pragma parameter BLOOM_MIX          "        Final mix, (0.0=off)"			0.2 0.0 1.0  0.01
#pragma parameter BLOOM_SIZE         "        Radius"					2.0  0.5 30.0 0.5
#pragma parameter BLOOM_QUALITY      "        Quality: more is better but slower"	2.0  2.0 32.0 1.0
#pragma parameter BLOOM_GAMMA        "        Input Gamma"				4.0  1.0 10.0 1.0
#pragma parameter BLOOM_POWER        "        Power multiplier"				8.0  1.0 10.0 0.1
#pragma parameter BLOOM_GAMMA_out    "        Output Gamma"				1.5  0.1 10.0 0.05
#pragma parameter BLOOM_BYPASS       "        Bypass"					0.0  0.0 1.0  1.0


// Gamma and SATURATION correction
// Correct the final gamma of the image
// To have more or less saturated colors use "SATURATION" > 1 or "SATURATION" < 1
#pragma parameter DO_CCORRECTION "★ Color corrections:" 			0.0 0.0 1.0 1.0
#pragma parameter GAMMA_OUT      "        Gamma output"			0.69	0.1 9.0  0.025
#pragma parameter SATURATION     "        Saturation modifier (1.0=off)"	1.0	0.0 10.0 0.025


//Curvature parameters:
#pragma parameter DO_CURVATURE	     "★ Curvature:"			0.0   0.0 1.0 1.0
#pragma parameter GEOM_WARP_X        "        Warp X"				0.02  0.0 0.1 0.01
#pragma parameter GEOM_WARP_Y        "        Warp Y"				0.0   0.0 0.1 0.01
#pragma parameter GEOM_CORNER_SIZE   "        Corner Size"			0.01  0.005 0.1 0.005
#pragma parameter GEOM_CORNER_SMOOTH "        Corner sharpness"			350.0 50.0 1000.0 25.0


//Bezel related
#pragma parameter DO_BEZEL	     "★ Bezel"				0.0   0.0 1.0 1.0
#pragma parameter BEZEL_R            "        Bezel color: Red"			-0.3   -0.5 0.5  0.01
#pragma parameter BEZEL_G            "        Bezel color: Green"		-0.3   -0.5 0.5  0.01
#pragma parameter BEZEL_B            "        Bezel color: Blue"		-0.3   -0.5 0.5  0.01
#pragma parameter BEZEL_CON          "        Bezel Contrast"			1.3   0.0  10.0 0.01
#pragma parameter BEZEL_INNER_ZOOM   "        Image zoom"			-0.18   -0.5 0.5 0.01
#pragma parameter BEZEL_FRAME_ZOOM   "        Frame zoom"			0.0   -0.5 0.5 0.01
#pragma parameter BEZEL_IMAGE_BORDER "        Image border"			1.01   1.0 1.2 0.01


//Full screen glowing
//Modulate the image zooming depending on the image luminosity.
//You can lower the effect power through the DYNZOOM_FACTOR parameter.
#pragma parameter DO_DYNZOOM	     "★ Luminosity dependant zoom"			1.0   0.0   1.0  1.0
#pragma parameter DYNZOOM_FACTOR     "        narrowness"				55.0  30.0  99.0 1.0

//Back leds
//Emulates leds under the monitor frame that slowly reacts to image contents
#pragma parameter DO_AMBILIGHT	 "★ Leds (needs Retroarch aspect ratio set to full!)"	1.0  0.0  1.0     1.0
#pragma parameter AMBI_STEPS	 "        Slowness"							60.0 5.0  1000.0  5.0
#pragma parameter AMBI_FALLOFF   "        Light Falloff"						0.7  0.1  3.0     0.01
#pragma parameter AMBI_POWER     "        Led power"							0.5  0.1  5.0     0.05
#pragma parameter ASPECT_X       "        Aspect Ratio Numerator (-x for a preset below)"   0.0  -5.0 256. 1.0
#pragma parameter ASPECT_Y       "        Aspect Ratio Denominator"	  				3.0   0.0 256. 1.0
#pragma parameter label_aspect_presets "        Presets reference list:" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset0 "          (0 =  MAME 1.33)" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset1 "          (-1 = NTSC 1.5)" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset2 "          (-2 = PAL 1.25)" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset3 "          (-3 = Snes 8/7)" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset4 "          (-4 = Megadrive 10/7)" 0.0 0.0 0.0 1.0
#pragma parameter label_aspect_preset5 "          (-5 = Uncorrected)" 0.0 0.0 0.0 1.0

//Vignette and spot
//Emulates the vignette effect and/or a light reflection.
#pragma parameter DO_VIGNETTE	"★ Vignette"			0.0  0.0  1.0  1.0
#pragma parameter V_BYPASS	"        bypass "	        	0.0  0.0  1.0  1.0
#pragma parameter V_SIZE	"        size"			1.7  0.0  3.0  0.05
#pragma parameter V_POWER	"        power"			1.1  0.05 2.0  0.05

#pragma parameter DO_SPOT	"★ Spot"			0.0   0.0   1.0 1.0
#pragma parameter S_BYPASS	"        bypass"	        0.0   0.0   1.0 1.0
#pragma parameter S_CENTER_X 	"        x position"	0.65  -1.5  1.5 0.05
#pragma parameter S_CENTER_Y	"        y postion "	-0.5  -1.5  1.5 0.05
#pragma parameter S_SIZE	"        size"		0.1   0.0  1.0 0.01
#pragma parameter S_POWER	"        power" 		0.15  0.05  2.0 0.05


// Alternative blanking.
// Emulates the low pixel persistance of CRT monitors and reduces the motion blur,
// typical of LCD displays, by blanking even/odd screen lines on even/odd frames.
// ALT_BLANK_STRENGTH expresses the strength of the "blank".
#pragma parameter DO_ALT_BLANK       "★ Alternate line blanking: " 					0.0 0.0 1.0 1.0
#pragma parameter ALT_BLANK_STRENGTH "        Alternate black frame insertion strength" 	0.5 0.0 1.0 0.1
#pragma parameter ALT_BLANK_PERIOD   "        Dark lines period" 	4.0 0.0 20.0 1.0


#define DO_FXAA        global.DO_FXAA
//#define prefer_std_pow params.prefer_std_pow

#define DO_SCANLINES                  global.DO_SCANLINES
#define SCANLINE_DARK                 params.SCANLINE_DARK
#define SCANLINE_OVERWHITE            global.SCANLINE_OVERWHITE
#define SCANLINE_FLICKERING           global.SCANLINE_FLICKERING
#define SCANLINE_DISABLE_ON_INTERLACE global.SCANLINE_DISABLE_ON_INTERLACE

#define DO_IN_GLOW               global.DO_IN_GLOW
#define IN_GLOW_ADD              global.IN_GLOW_ADD
#define GLOW_OVER_DARK_SCANLINES global.GLOW_OVER_DARK_SCANLINES
#define IN_GLOW_WH               global.IN_GLOW_WH
#define IN_GLOW_POWER            global.IN_GLOW_POWER
#define IN_GLOW_GAMMA            global.IN_GLOW_GAMMA

#define DO_RGB_MASK       global.DO_RGB_MASK
#define RGB_MASK_STRENGTH global.RGB_MASK_STRENGTH
#define VMASK_OVERWHITE   params.VMASK_OVERWHITE

#define DO_DARKLINES         global.DO_DARKLINES
#define DARKLINES_STRENGTH   global.DARKLINES_STRENGTH
#define DRKLN_OVERWHITE      params.DRKLN_OVERWHITE
#define DO_DARKLINES_VOFFSET params.DO_DARKLINES_VOFFSET
#define DARKLINES_PERIOD     params.DARKLINES_PERIOD

#define DO_HALO    global.DO_HALO
#define HALO_W     params.HALO_W
#define HALO_H     params.HALO_H
#define HALO_POWER params.HALO_POWER
#define HALO_GAMMA params.HALO_GAMMA

#define DO_BLOOM           params.DO_BLOOM
#define BLOOM_MIX          global.BLOOM_MIX
#define BLOOM_QUALITY      params.BLOOM_QUALITY
#define BLOOM_SIZE         global.BLOOM_SIZE
#define BLOOM_GAMMA        global.BLOOM_GAMMA
#define BLOOM_POWER        global.BLOOM_POWER
#define BLOOM_GAMMA_out    global.BLOOM_GAMMA_out
#define BLOOM_BYPASS       global.BLOOM_BYPASS

#define DO_CCORRECTION global.DO_CCORRECTION
#define GAMMA_OUT      global.GAMMA_OUT
#define SATURATION     global.SATURATION

#define DO_ALT_BLANK       global.DO_ALT_BLANK
#define ALT_BLANK_STRENGTH global.ALT_BLANK_STRENGTH
#define ALT_BLANK_PERIOD global.ALT_BLANK_PERIOD


#define DO_CURVATURE       global.DO_CURVATURE
#define GEOM_WARP_X        global.GEOM_WARP_X
#define GEOM_WARP_Y        global.GEOM_WARP_Y
#define GEOM_CORNER_SIZE   global.GEOM_CORNER_SIZE
#define GEOM_CORNER_SMOOTH global.GEOM_CORNER_SMOOTH


#define DO_BEZEL           global.DO_BEZEL
#define BEZEL_R            global.BEZEL_R
#define BEZEL_G            global.BEZEL_G
#define BEZEL_B            global.BEZEL_B
#define BEZEL_CON          global.BEZEL_CON
#define BEZEL_INNER_ZOOM   global.BEZEL_INNER_ZOOM
#define BEZEL_FRAME_ZOOM   global.BEZEL_FRAME_ZOOM
#define BEZEL_IMAGE_BORDER global.BEZEL_IMAGE_BORDER

#define DO_SPOT    global.DO_SPOT
#define S_BYPASS   global.S_BYPASS
#define S_CENTER_X global.S_CENTER_X
#define S_CENTER_Y global.S_CENTER_Y
#define S_SIZE     global.S_SIZE
#define S_POWER    global.S_POWER

#define DO_DYNZOOM      global.DO_DYNZOOM
#define DYNZOOM_FACTOR  global.DYNZOOM_FACTOR

#define DO_VIGNETTE  global.DO_VIGNETTE
#define V_BYPASS     global.V_BYPASS
#define V_SIZE       global.V_SIZE
#define V_POWER      global.V_POWER

#define DO_AMBILIGHT global.DO_AMBILIGHT
#define AMBI_STEPS   global.AMBI_STEPS
#define AMBI_FALLOFF global.AMBI_FALLOFF
#define AMBI_POWER   global.AMBI_POWER
#define ASPECT_X	global.ASPECT_X
#define ASPECT_Y	global.ASPECT_Y
