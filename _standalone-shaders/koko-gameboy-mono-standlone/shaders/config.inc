	//Static dithering applied over vignette and spot
#define NOISEPOWER 5/1000.0


#define eps 1e-5
#define pi  3.141592653589793


layout(push_constant) uniform Push {
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
} params;

layout(std140, set = 0, binding = 0) uniform UBO {
	mat4 MVP;
	
	vec4 FinalViewportSize;
	vec4 flick_and_noise_passSize;
	vec4 colortools_and_ntsc_passSize;

	float COLOR_MONO_COLORIZE;
	float COLOR_MONO_HUE1;
	float COLOR_MONO_HUE2;
	float COLOR_MONO_HUE_BIAS;

	float GAMMA_OUT ; //1
	float GAMMA_IN;
	float SATURATION;
	float LUMINANCE;
	float CONTRAST;
	float BRIGHTNESS;
	float TEMPERATURE;
	
	float DO_SPOT;
	float S_POSITION; 
	float S_SIZE;
	float S_POWER;

	float DO_VIGNETTE;
	float V_SIZE;
	float V_POWER;

	float ASPECT_X;
	float ASPECT_Y;

	float DO_GAME_GEOM_OVERRIDE;
	float GAME_GEOM_INT_SCALE;
	float GAME_GEOM_INT_SCALE_MAX;
	float GAME_GEOM_ASPECT;
	float GAME_GEOM_VSHIFT;
	float GAME_GEOM_HSHIFT;
	float GAME_GEOM_ZOOM;
	

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
	
} global;

// Color correction
#pragma parameter GAMMA_IN      "        Gamma in"				2.0	0.1 	4.0  0.01
#pragma parameter LUMINANCE       "        Luminance push (>1.0=clip)"		0.0	 0.0 1.5 0.05
#pragma parameter BRIGHTNESS     "        Brightness in   (0.0=off)"		0.0	-1.0 1.0 0.01
#pragma parameter CONTRAST       "        Contrast in     (0.0=off)"		0.0	-1.0 1.0 0.01
#pragma parameter TEMPERATURE    "        Temperature in (6500=off)"		6500.0	3000 10000.0 50.0
#pragma parameter GAMMA_OUT      "        Gamma out"				0.5	0.1 	4.0  0.01
#pragma parameter COLOR_MONO_COLORIZE	"        Monochrome screen colorization"	0.0  0.0 1.0 0.1
#pragma parameter COLOR_MONO_HUE1        "           . Hue bright"					0.25 0.0 1.0 0.01
#pragma parameter COLOR_MONO_HUE2        "           . Hue dark"						0.3  0.0 1.0 0.01
#pragma parameter COLOR_MONO_HUE_BIAS    "           . Hue bright-dark bias"		0.0	-2.0 2.0 0.01
#pragma parameter SATURATION     "        Saturation in   (1.0=off)"		1.0	0.0  2.0 0.01
#pragma parameter BLANK1 " " 0.0 0.0 1.0 1.0


// Dot matrix emulation
#pragma parameter DOT_M_G_STR		"        Grid strength"					0.0 0.0 1.0 0.01
#pragma parameter DOT_M_G_TRESH		"           . Paint on bright (<0 on black)"	1.1 -1.1 1.1 0.01
#pragma parameter DOT_M_G_BRT		"           . Grid brightness"			0.0 0.0 1.0 0.01
#pragma parameter DOT_M_G_SHARP		"           . Grid sharpness"			2.0 0.0 20.0 0.25
#pragma parameter DOT_M_RGB_STR		"        RGB strength"					1.0 0.0 1.0 0.01
#pragma parameter DOT_M_RGB_SHARP	"           . RGB sharpness"					2.0 0.1 16.0 0.01
#pragma parameter DOT_M_G_GAIN  	"           . RGB Green gain correction"		0.85 0.1 1.0 0.01
#pragma parameter DOT_M_MBLUR_STR	"        Refresh inertia"				0.45  0.0 0.9 0.05
#pragma parameter DOT_M_MBLUR_MODE  "           . Inertia on: both,white,black"	0.0  0.0 2.0 1.0
#pragma parameter DOT_M_SHADOW_STR  "        Shadow strength (disables deconvergence)"	0.0  0.0 1.0 0.01
#pragma parameter DOT_M_SHADOW_OFF  "        Shadow offset"								0.0  -1.0 1.0 0.1

#pragma parameter DOT_M_MULTIPLY	"        Multiply factor (debug)"		1.0  1.0 50.0 1.0
#pragma parameter BLANK12c " " 0.0 0.0 1.0 1.0




//Vignette and spot
#pragma parameter DO_VIGNETTE	"★ Vignette enable? ==>"	0.0  0.0  1.0  1.0
#pragma parameter V_SIZE	"        Size"			1.7  0.0  5.0  0.05
#pragma parameter V_POWER	"        Power"			1.1  0.05 2.0  0.01

#pragma parameter DO_SPOT	"★ Spot enable? ==>"		0.0   0.0   1.0 1.0
#pragma parameter S_POSITION 	"        Position"		0.0   -420.0 378.0 1
#pragma parameter S_SIZE	"        Size"			0.4   0.0   1.0 0.01
#pragma parameter S_POWER	"        Power" 		0.1   0.05  2.0 0.01
#pragma parameter BLANK19 " " 0.0 0.0 1.0 1.0



//Aspect Ratio
#pragma parameter label_ar	 "★ Aspect Ratio "							0.0  0.0  1.0     1.0
#pragma parameter ASPECT_X       "        Aspect Ratio Numerator"   		0.0  -6.0 256. 1.0
#pragma parameter ASPECT_Y       "        Aspect Ratio Denominator"	  				3.0   0.0 256. 1.0
#pragma parameter BLANK22 " " 0.0 0.0 1.0 1.0


//Content geomerty overrides
#pragma parameter GAME_GEOM_INT_SCALE     "        Integer scale (disables inner zoom) 2=No keep aspect"	0.0   0.0  2.0    1.0
#pragma parameter GAME_GEOM_INT_SCALE_MAX "        Maximum integer scale" 				10.0  1.0  100.0  1.0
#pragma parameter BLANK20 " " 0.0 0.0 1.0 1.0


#define GAMMA_OUT	global.GAMMA_OUT
#define GAMMA_IN	global.GAMMA_IN
#define SATURATION	global.SATURATION
#define LUMINANCE	global.LUMINANCE
#define CONTRAST	global.CONTRAST
#define BRIGHTNESS	global.BRIGHTNESS
#define TEMPERATURE	global.TEMPERATURE
#define COLOR_MONO_COLORIZE 	global.COLOR_MONO_COLORIZE
#define COLOR_MONO_HUE1		global.COLOR_MONO_HUE1
#define COLOR_MONO_HUE2		global.COLOR_MONO_HUE2
#define COLOR_MONO_HUE_BIAS global.COLOR_MONO_HUE_BIAS


#define DO_SPOT		global.DO_SPOT
#define S_POSITION	global.S_POSITION
#define S_SIZE		global.S_SIZE
#define S_POWER		global.S_POWER

#define DO_VIGNETTE	global.DO_VIGNETTE
#define V_SIZE		global.V_SIZE
#define V_POWER		global.V_POWER

#define ASPECT_X		global.ASPECT_X
#define ASPECT_Y		global.ASPECT_Y

#define GAME_GEOM_INT_SCALE	global.GAME_GEOM_INT_SCALE
#define GAME_GEOM_INT_SCALE_MAX global.GAME_GEOM_INT_SCALE_MAX

#define DOT_M_G_SHARP	global.DOT_M_G_SHARP
#define DOT_M_RGB_SHARP	global.DOT_M_RGB_SHARP
#define DOT_M_RGB_STR	global.DOT_M_RGB_STR
#define DOT_M_G_TRESH	global.DOT_M_G_TRESH
#define DOT_M_G_BRT		global.DOT_M_G_BRT
#define DOT_M_G_GAIN	global.DOT_M_G_GAIN
#define DOT_M_G_STR		global.DOT_M_G_STR
#define DOT_M_MBLUR_STR		global.DOT_M_MBLUR_STR
#define DOT_M_MBLUR_MODE	global.DOT_M_MBLUR_MODE
#define DOT_M_MULTIPLY  	global.DOT_M_MULTIPLY
#define DOT_M_SHADOW_STR	global.DOT_M_SHADOW_STR
#define DOT_M_SHADOW_OFF	global.DOT_M_SHADOW_OFF

