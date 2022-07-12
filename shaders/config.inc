#define eps 1e-8

layout(push_constant) uniform Push
{
	vec4 SourceSize;
	vec4 OriginalSize;
	vec4 OutputSize;
	uint FrameCount;
	float SCANLINE_DARK;
	float IN_GLOW_ADD ;
	float in_glow_wh ;
	float in_glow_power ;
	float in_glow_gamma ;
	float DO_RGB_MASK ;
	float VMASK_OVERWHITE ;
	float DO_DARKLINES ;
	float DRKLN_OVERWHITE ;
	float DO_DARKLINES_VOFFSET ;
	float DARKLINES_PERIOD ;
	float DO_HALO ;
	float halo_wh ;
	float halo_power ;
	float halo_gamma ;
	float DO_BLOOM ;
 	float bloom_directions ;
 	float bloom_quality ;
 	float bloom_size ;
} params;

layout(std140, set = 0, binding = 0) uniform UBO
{
	mat4 MVP;
	float bloom_gamma;
	float bloom_on_dark_only;
	float bloom_power;
  	float GAMMA_R ;
  	float GAMMA_G ;
  	float GAMMA_B ;
  	float saturation ;
  	float DO_ALT_BLANK ;
	float DO_FXAA ;
	float scanline_sharpness ;
	float scanline_flickering ;
} global;


// PARAMETERS AND MEANING


// FXAA
// Apply an antialiasing filter via FXAA from nvidia, Boolean.
#pragma parameter DO_FXAA "[FXAA]  1.0 to enable"	1.0 	0.0 1.0 1.0



// Scanlines
// Blank even source lines, the value from 0.0 to 1.0 expresses the darkness of the blanked lines
// 1.0 means no blank at all.
#pragma parameter SCANLINE_DARK "[Scanlines] Dark scanline brightness, (1.0=off)"		  	1.0 	0.0 1.0 0.05

// The amount of scanline sharpness. Very high values may cause visual artifacts when using not integer scaling
#pragma parameter scanline_sharpness "[Scanlines] Sharpness (use 15 for maximum on integer scaling)"	  	10.0 	1.0 15.0 0.2

// Alternate the drawing of the scanlines between frames. this will produce a flickering typical of
// interlaced screens; 0 disable the effect, 1 always enables it, 2 enables it only when
// the shader detects an interlaced signal, which actually means that the vertical resoution is "high enough"
#pragma parameter scanline_flickering "[Scanlines] Flicker (0=off,1=on,2=if interlaced)"		  	2.0 	0.0 2.0 1.0



// Input glowing
// Emulates the glowing of the input signal by blurring it with "in_glow_wh" sharpness,
// apply a gamma filter "in_glow_gamma" to "light" it, multiplying the result by "in_glow_power" and
// finally interpolating(*) it with the source image.
// "IN_GLOW_ADD" allows to modulate from interpolation(*) to a sum. This will allow the glow to light the unscanned
// line, wihch may (or not) produce better effects when emulating scanlines.
// With "IN_GLOW_ADD=0" input glowing does not normally alter the RGB mask
// or slot mask applied to the image.
#pragma parameter in_glow_power "[In Glow] Input signal glow strength (neg=off)"			0.45 	-0.05 10.0 0.05
#pragma parameter in_glow_wh    "[In Glow] Sharpness"										2.5 	0.0 10.0 0.05
#pragma parameter in_glow_gamma "[In Glow] Gamma, the higher, the less the glow on dark colors"	1.0 	1.0 9.0 1.0
#pragma parameter IN_GLOW_ADD   "[In Glow] Overflows from the scanlines, sharper image"		0.0 	0.0 1.0 0.05



// RGB Mask
// Emulates CRT RGB phosphors.
// This is done by multiplying the source image pixels, in turn, by red green or blue.
// The strenght of the multiplication, and so of the final effect is affected by "DO_RGB_MASK" value.
// A Value of 0 completely disable the effect.
// "VMASK_OVERWHITE" modulates the strenght of the effect depending on the source pixel brightness,
// This is handy  if you want to keep a good image contrast/brightness, but keep in mind that other
// parameters like haloing and bloom.
#pragma parameter DO_RGB_MASK "[RGB Mask] Strength (0.0=off)"					0.75  	0.0 1.0 0.05
#pragma parameter VMASK_OVERWHITE "[RGB Mask] Affects bright colors" 				1.0 	0.0 1.0 0.05



// Aperture grille/slot mask (shadow mask not implemented)
// Draw darklines on screen coordinates, by mixing black pixels with the source image
// on final viewport coordinates.
// "DO_DARKILNES" expresses the final strenght of the effect.
// if "DO_DARKLINES_VOFFSET" is 0, straight horizontal black lines will be painted that emulates an aperture grille.
// "DARKLINES_PERIOD" expresses every how many lines draw a black one.
// "DO_DARKLINES_VOFFSET" lets you to vertically offset by ""DARKLINES_PERIOD/2" the lines every 3 screen pixels,
// allowing, in conjunction with RGB mask, to emulate slot mask
#pragma parameter DO_DARKLINES "[Dark screenlines] Slotmask/aperture grille strength"	0.3 	0.0 1.0 0.05
#pragma parameter DO_DARKLINES_VOFFSET "[Dark screenlines]  Offset by triads"		1.0 	0.0 1.0 1.0
#pragma parameter DARKLINES_PERIOD "[Dark screenlines] Period"				4.0 	-8.0 8.0 2.0
#pragma parameter DRKLN_OVERWHITE "[Dark screenlines] Affects bright colors"		1.0 	0.0 1.0 0.05



// Halo
// The parameters are the same as input glowing, but this time the effect is applie
// after emulating the RGB phosphors the aperture grille or the slot masks and, instead of
// multiplying the resulting picture by the source one, it is added.
// this means that haloing will produce solid colors,
// lessening afromentioned effects on bright colors.
#pragma parameter halo_power "[Halo] Strength (neg=off)"					0.9 	-0.05 10.0 0.05
#pragma parameter halo_wh "[Halo] Sharpness"							1.75 	0.0  10.0 0.05
#pragma parameter halo_gamma "[Halo] Gamma, the higher, the less the halo on dark colors"	2.0 	2.0  9.0 1.0



// Bloom
// The image is downsampled, bloomed and mixed back with the original image.
// "DO_BLOOM" is the final mix strength
// "bloom_size" is the radius of the blurred image
// "bloom_directions" and "bloom_quality" express a tradeoff between quality and effect speed.
// "bloom_gamma" allows to apply more bloom on the bright colors of the source image
// "bloom_power" is the additional gain applied to the bloom
// "bloom_on_dark_only" will mix the bloomed image with the original depending on the brightness of
// the original image.
#pragma parameter DO_BLOOM "[Bloom] final mix, (0.0=off)"				0.15	0.0 1.0 0.01
#pragma parameter bloom_size "[Bloom] Radius"						0.25 	0.1 3.0 0.05
#pragma parameter bloom_directions "[Bloom] Directions: more is better but slower"	8.0	4.0 64.0 4.0
#pragma parameter bloom_quality "[Bloom] Quality: more is better but slower"		8.0	2.0 32.0 1.0
#pragma parameter bloom_gamma "[Bloom] Bloom gamma"					2.0	1.0 9.0 1.0
#pragma parameter bloom_power "[Bloom] Bloom power multiplier"				2.0	1.0 10.0 0.1
#pragma parameter bloom_on_dark_only "[Bloom] Bloom only over dark areas"		1.0	0.0 1.0 1.0



// Gamma and saturation correction
// Correct the final gamma of the image; you can tint it by assign different values to
// GAMMA_R, GAMMA_G and GAMMA_B
// To have more or less saturated colors use "saturation" > 1 or "saturation" < 1
#pragma parameter GAMMA_R "[Gamma] red. The higher, the darker."	0.69	 0.1 9.0 0.05
#pragma parameter GAMMA_G "[Gamma] green. The higher, the darker."	0.69	 0.1 9.0 0.05
#pragma parameter GAMMA_B "[Gamma] blue. The higher, the darker."	0.69	 0.1 9.0 0.05
#pragma parameter saturation "[Saturation] modifier (1.0=off)"		1.0	 0.0 10.0 0.05



// Alternative blanking.
// Emulates the low pixel persistance of CRT monitors and reduces the motion blur,
// typical of LCD displays, by blanking even/odd screen lines on even/odd frames.
// DO_ALT_BLANK expresses the strength of the "blank".
#pragma parameter DO_ALT_BLANK "Black frame insertion strength" 	0.0 0.0 1.0 0.1





#define SCANLINE_DARK params.SCANLINE_DARK
#define scanline_sharpness global.scanline_sharpness
#define scanline_flickering global.scanline_flickering

#define IN_GLOW_ADD params.IN_GLOW_ADD
// #define in_glow_w params.in_glow_w
// #define in_glow_h params.in_glow_h
#define in_glow_wh params.in_glow_wh
#define in_glow_power params.in_glow_power
#define in_glow_gamma params.in_glow_gamma

#define DO_RGB_MASK params.DO_RGB_MASK
#define VMASK_OVERWHITE params.VMASK_OVERWHITE

#define DO_DARKLINES params.DO_DARKLINES
#define DRKLN_OVERWHITE params.DRKLN_OVERWHITE
#define DO_DARKLINES_VOFFSET params.DO_DARKLINES_VOFFSET
#define DARKLINES_PERIOD params.DARKLINES_PERIOD

#define DO_HALO params.DO_HALO
// #define halo_w params.halo_w
// #define halo_h params.halo_h
#define halo_wh params.halo_wh
#define halo_power params.halo_power
#define halo_gamma params.halo_gamma

#define DO_BLOOM params.DO_BLOOM
#define bloom_directions params.bloom_directions
#define bloom_quality params.bloom_quality
#define bloom_size params.bloom_size
#define bloom_gamma global.bloom_gamma
#define bloom_power global.bloom_power
#define bloom_on_dark_only global.bloom_on_dark_only

#define GAMMA global.GAMMA
#define GAMMA_R global.GAMMA_R
#define GAMMA_G global.GAMMA_G
#define GAMMA_B global.GAMMA_B

#define saturation global.saturation

#define DO_ALT_BLANK global.DO_ALT_BLANK

#define DO_FXAA global.DO_FXAA
