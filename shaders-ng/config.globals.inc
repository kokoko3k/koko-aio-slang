/* There yoy have a chance to boost your FPS.
 * 
 * The more lines you edit, the more your FPS will be high.
 * 
 * Edit lines that way, eg:
 * 
 * 	#define SCANLINE_DARK	params.SCANLINE_DARK
 * 	turns to:
 * 	#define SCANLINE_DARK	0.2
 * 
 * or:
 * 	#define DO_CCORRECTION	global.DO_CCORRECTION
 * 	turns to
 * 	#define DO_CCORRECTION	0.0
 *
 * 
 * Since everything after "//" is ignored,
 * you can even do something like:
 * 	#define DO_CCORRECTION	0.0 //global.DO_CCORRECTION
 * 
 * 
 * ...that's it, you just need to copy the values from the
 * preset you like to the right setting here.
 * 
 * The downside of using this method is that every setting
 * you turn, will be static and you will not be able to
 * modify it "on-the-fly" in retroarch.
 * 
 * The only way to change that values will be to edit this file
 * again, so maybe doing multiple copies of this file
 * or even of the whole koko-shader would be a good idea.
 * 
 * 
 * I suggest you to start from the easy ones, the ones that
 * starts with DO_****, like DO_SCANLINES.
 * it takes a value = 0 or 1, where 0 means no, 1 means yes.
 * I repeat: if you always wants scanlines, just use:
 * 
 * 	#define DO_SCANLINES		1.0
 * 	instead of
 * 	#define #DO_SCANLINES	global.DO_SCANLINES
 * 
 * 
 * Also, take a copy of this (modified) file, because it would be overwritten by
 * updates.
 * 
 */



#define DO_CCORRECTION	global.DO_CCORRECTION
	#define GAMMA_OUT	global.GAMMA_OUT
	#define SATURATION	global.SATURATION
	#define LUMINANCE	global.LUMINANCE
	#define CONTRAST	global.CONTRAST
	#define BRIGHTNESS	global.BRIGHTNESS
	#define TEMPERATURE	global.TEMPERATURE
	#define COLOR_MONO_COLORIZE 	global.COLOR_MONO_COLORIZE
	#define COLOR_MONO_HUE1		global.COLOR_MONO_HUE1
	#define COLOR_MONO_HUE2		global.COLOR_MONO_HUE2
	#define COLOR_MONO_HUE_BIAS global.COLOR_MONO_HUE_BIAS


	#define DO_FXAA	global.DO_FXAA



#define DO_NTSC_ARTIFACTS	global.DO_NTSC_ARTIFACTS
	#define NTSC_FILTER_WIDTH		global.NTSC_FILTER_WIDTH
	#define NTSC_FILTER_SCF			global.NTSC_FILTER_SCF
	#define NTSC_FILTER_FC			global.NTSC_FILTER_FC
	#define NTSC_MIX				global.NTSC_MIX
	#define NTSC_PHASE_SHIFT		global.NTSC_PHASE_SHIFT
	#define NTSC_ARTF_NOBLUR 		global.NTSC_ARTF_NOBLUR
	#define NTSC_ARTF_NOBLEED 		global.NTSC_ARTF_NOBLEED
	#define NTSC_ARTF_TRSH 			global.NTSC_ARTF_TRSH
	#define NTSC_SHOW_ARTF_MASK 	global.NTSC_SHOW_ARTF_MASK
	#define NTSC_ARTF_ZAP			global.NTSC_ARTF_ZAP

#define DO_RF_NOISE		global.DO_RF_NOISE
	#define RF_NOISE_STRENGTH	global.RF_NOISE_STRENGTH



#define DO_SAT_BLEED		global.DO_SAT_BLEED
	#define SAT_BLEED_SIZE_LEFT	global.SAT_BLEED_SIZE_LEFT
	#define SAT_BLEED_SIZE_RIGHT	global.SAT_BLEED_SIZE_RIGHT
	#define SAT_BLEED_FALLOFF	global.SAT_BLEED_FALLOFF
	#define SAT_BLEED_STRENGTH	global.SAT_BLEED_STRENGTH
	#define SAT_BLEED_PAL		global.SAT_BLEED_PAL



#define DO_SHIFT_RGB		global.DO_SHIFT_RGB
	#define SHIFT_R			global.SHIFT_R
	#define SHIFT_G			global.SHIFT_G
	#define SHIFT_B			global.SHIFT_B
	#define OFFSET_STRENGTH	global.OFFSET_STRENGTH



#define DO_IN_GLOW		global.DO_IN_GLOW
	#define IN_GLOW_BIAS			global.IN_GLOW_BIAS
	#define IN_GLOW_SPREAD			global.IN_GLOW_SPREAD
	#define IN_GLOW_W				global.IN_GLOW_W
	#define IN_GLOW_H				global.IN_GLOW_H
	#define IN_GLOW_POWER			global.IN_GLOW_POWER
	#define IN_GLOW_GAMMA			global.IN_GLOW_GAMMA
	#define IN_GLOW_NTSC_ARTF_MULT	global.IN_GLOW_NTSC_ARTF_MULT
	#define IN_GLOW_NTSC_ARTF_TRSH	global.IN_GLOW_NTSC_ARTF_TRSH
	#define IN_GLOW_SHOW_ARTF_MASK  global.IN_GLOW_SHOW_ARTF_MASK


#define DO_HALO		global.DO_HALO
	#define HALO_SHARPNESS	params.HALO_SHARPNESS
	#define HALO_NO_PREGAIN params.HALO_NO_PREGAIN
	#define HALO_POWER	params.HALO_POWER
	#define HALO_GAMMA	params.HALO_GAMMA
	#define HALO_VS_SCAN	params.HALO_VS_SCAN
	#define HALO_GAMMA_OUT	params.HALO_GAMMA_OUT



#define DO_BLOOM		params.DO_BLOOM
	#define BLOOM_MIX		global.BLOOM_MIX
	#define BLOOM_EYE_ADPT_SRT	global.BLOOM_EYE_ADPT_SRT
	#define BLOOM_EYE_INERTIA	global.BLOOM_EYE_INERTIA
	#define BLOOM_QUALITY		params.BLOOM_QUALITY
	#define BLOOM_SIZE		global.BLOOM_SIZE
	#define BLOOM_GAMMA		global.BLOOM_GAMMA
	#define BLOOM_POWER		global.BLOOM_POWER
	#define BLOOM_GAMMA_OUT		global.BLOOM_GAMMA_OUT
	#define BLOOM_OVER_WHITE	global.BLOOM_OVER_WHITE
	#define BLOOM_BYPASS		global.BLOOM_BYPASS



#define DO_CURVATURE		global.DO_CURVATURE
	#define GEOM_WARP_X		global.GEOM_WARP_X
	#define GEOM_WARP_Y		global.GEOM_WARP_Y
	#define GEOM_CUT_EARS	global.GEOM_CUT_EARS
	#define GEOM_CORNER_SIZE	global.GEOM_CORNER_SIZE
	#define GEOM_CORNER_SMOOTH	global.GEOM_CORNER_SMOOTH



#define DO_BEZEL		global.DO_BEZEL
	#define BEZEL_R			global.BEZEL_R
	#define BEZEL_G			global.BEZEL_G
	#define BEZEL_B			global.BEZEL_B
	#define BEZEL_CON		global.BEZEL_CON
	#define BEZEL_INNER_ZOOM	global.BEZEL_INNER_ZOOM
	#define BEZEL_FRAME_ZOOM	global.BEZEL_FRAME_ZOOM
	#define BEZEL_USE_STRAIGHT	global.BEZEL_USE_STRAIGHT
	#define BEZEL_RFL_BLR_SHD	global.BEZEL_RFL_BLR_SHD
	#define BEZEL_RFL_ZOOM		global.BEZEL_RFL_ZOOM
	#define BEZEL_REFL_STRENGTH	global.BEZEL_REFL_STRENGTH
	#define BEZEL_SPCL_STRENGTH	global.BEZEL_SPCL_STRENGTH
	#define BEZEL_DIFFUSION_STR global.BEZEL_DIFFUSION_STR
	#define BEZEL_CORNER_DARK   global.BEZEL_CORNER_DARK
	#define BEZEL_ROUGHNESS		global.BEZEL_ROUGHNESS
	
#define DO_SPOT		global.DO_SPOT
	#define S_POSITION	global.S_POSITION
	#define S_SIZE		global.S_SIZE
	#define S_POWER		global.S_POWER



#define DO_VIGNETTE	global.DO_VIGNETTE
	#define V_SIZE		global.V_SIZE
	#define V_POWER		global.V_POWER



#define DO_BG_IMAGE		global.DO_BG_IMAGE
	#define BG_IMAGE_OVER		global.BG_IMAGE_OVER
	#define BG_IMAGE_OFFY		global.BG_IMAGE_OFFY
	#define BG_IMAGE_OFFX		global.BG_IMAGE_OFFX
	#define BG_IMAGE_ZOOM		global.BG_IMAGE_ZOOM
	#define BG_IMAGE_ROTATION	global.BG_IMAGE_ROTATION
	#define BG_IMAGE_WRAP_MODE	global.BG_IMAGE_WRAP_MODE
	#define BG_IMAGE_NIGHTIFY   global.BG_IMAGE_NIGHTIFY

#define DO_BACKDROP		global.DO_BACKDROP
	#define BACKDROP_OFFX		global.BACKDROP_OFFX
	#define BACKDROP_OFFY		global.BACKDROP_OFFY
	#define BACKDROP_ZOOM		global.BACKDROP_ZOOM
	

#define DO_AMBILIGHT		global.DO_AMBILIGHT
	#define AMBI_STEPS			global.AMBI_STEPS
	#define AMBI_FALLOFF			global.AMBI_FALLOFF
	#define AMBI_POWER			global.AMBI_POWER
	#define AMBI_GAMMA			global.AMBI_GAMMA
	#define AMBI_STRETCH		params.AMBI_STRETCH
	#define AMBI_OVER_BEZEL			global.AMBI_OVER_BEZEL
	#define AMBI_OVER_BEZEL_SIZE		global.AMBI_OVER_BEZEL_SIZE
	#define AMBI_BG_IMAGE_BLEND_MODE	global.AMBI_BG_IMAGE_BLEND_MODE
	#define AMBI_BG_IMAGE_FORCE		global.AMBI_BG_IMAGE_FORCE
	#define AMBI_ADD_ON_BLACK		params.AMBI_ADD_ON_BLACK
	#define AMBI_INT_OFFSET			params.AMBI_INT_OFFSET

//Global aspect ratio related
	#define ASPECT_X		global.ASPECT_X
	#define ASPECT_Y		global.ASPECT_Y
	

#define DO_DYNZOOM		global.DO_DYNZOOM
	#define DYNZOOM_FACTOR		80 //global.DYNZOOM_FACTOR


#define DO_ALT_BLANK		global.DO_ALT_BLANK
	#define ALT_BLANK_STRENGTH	global.ALT_BLANK_STRENGTH
	#define ALT_BLANK_PERIOD	global.ALT_BLANK_PERIOD


#define DO_GLOBAL_SHZO	global.DO_GLOBAL_SHZO
	#define GLOBAL_ZOOM	global.GLOBAL_ZOOM
	#define GLOBAL_OFFX	global.GLOBAL_OFFX
	#define GLOBAL_OFFY	global.GLOBAL_OFFY

	
#define DO_GAME_GEOM_OVERRIDE	global.DO_GAME_GEOM_OVERRIDE
	#define GAME_GEOM_INT_SCALE	global.GAME_GEOM_INT_SCALE
	#define GAME_GEOM_INT_SCALE_MAX global.GAME_GEOM_INT_SCALE_MAX
	#define GAME_GEOM_ASPECT 	global.GAME_GEOM_ASPECT
	#define GAME_GEOM_VSHIFT 	global.GAME_GEOM_VSHIFT
	#define GAME_GEOM_HSHIFT 	global.GAME_GEOM_HSHIFT
	#define GAME_GEOM_ZOOM		global.GAME_GEOM_ZOOM
	#define GAME_GEOM_OFF_FIX   global.GAME_GEOM_OFF_FIX
	
	#define DO_TILT			global.DO_TILT
	#define TILT_X			global.TILT_X
	#define TILT_Y			global.TILT_Y
	#define TILT_FOV		global.TILT_FOV
	#define TILT_BEZEL_K	global.TILT_BEZEL_K

#define TATE	global.TATE

#define DO_DOT_MATRIX	global.DO_DOT_MATRIX
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

	#define MIN_LINES_INTERLACED global.MIN_LINES_INTERLACED

#define DO_PIXELGRID			global.DO_PIXELGRID
	#define PIXELGRID_OVERMASK	global.PIXELGRID_OVERMASK
	#define DO_PIXELGRID_W		global.DO_PIXELGRID_W
	#define DO_PIXELGRID_H		global.DO_PIXELGRID_H
	//#define PIXELGRID_HMASK_NO_BRIGHT global.PIXELGRID_HMASK_NO_BRIGHT
	#define PIXELGRID_MIN_H 	global.PIXELGRID_MIN_H
	#define PIXELGRID_MIN_W 	global.PIXELGRID_MIN_W
	#define PIXELGRID_MAX_H	 	global.PIXELGRID_MAX_H
	#define PIXELGRID_MAX_W 	global.PIXELGRID_MAX_W
	#define PIXELGRID_SIZE_W 	global.PIXELGRID_SIZE_W
	#define PIXELGRID_GAMMA_H	global.PIXELGRID_GAMMA_H
	#define PIXELGRID_SMOOTH_W 	global.PIXELGRID_SMOOTH_W
	#define PIXELGRID_SMOOTH_H 	global.PIXELGRID_SMOOTH_H
	#define PIXELGRID_MUL_X 	global.PIXELGRID_MUL_X
	#define PIXELGRID_NO_INTERBLEED_W global.PIXELGRID_NO_INTERBLEED_W
	#define PIXELGRID_NO_INTERBLEED_H global.PIXELGRID_NO_INTERBLEED_H
	#define PIXELGRID_H_DEDOT	global.PIXELGRID_H_DEDOT
	#define PIXELGRID_BASAL_GRID global.PIXELGRID_BASAL_GRID
	
	#define PIXELGRID_DECON_R_H		global.PIXELGRID_DECON_R_H
	#define PIXELGRID_DECON_G_H		global.PIXELGRID_DECON_G_H
	#define PIXELGRID_DECON_B_H		global.PIXELGRID_DECON_B_H
	
	#define PIXELGRID_Y_MASK	global.PIXELGRID_Y_MASK
	#define PIXELGRID_Y_MASK_HEIGHT	global.PIXELGRID_Y_MASK_HEIGHT
	#define PIXELGRID_Y_MASK_OFFSET global.PIXELGRID_Y_MASK_OFFSET
	#define PIXELGRID_Y_MASK_STEEP global.PIXELGRID_Y_MASK_STEEP
	#define PIXELGRID_Y_MASK_ON_WHITE global.PIXELGRID_Y_MASK_ON_WHITE
	#define PIXELGRID_Y_MASK_COORDS global.PIXELGRID_Y_MASK_COORDS
	#define PIXELGRID_OFFSET_CORE global.PIXELGRID_OFFSET_CORE
	#define PIXELGRID_Y_MASK_SHIFT global.PIXELGRID_Y_MASK_SHIFT
	#define PIXELGRID_Y_SPARK global.PIXELGRID_Y_SPARK
	
	
	#define PIXELGRID_R_SHIFT global.PIXELGRID_R_SHIFT
	#define PIXELGRID_G_SHIFT global.PIXELGRID_G_SHIFT
	#define PIXELGRID_B_SHIFT global.PIXELGRID_B_SHIFT
	#define PIXELGRID_H_COUNT global.PIXELGRID_H_COUNT
	#define PIXELGRID_H_PRST  global.PIXELGRID_H_PRST

	#define PIXELGRID_INTR_FLICK_MODE global.PIXELGRID_INTR_FLICK_MODE
	#define PIXELGRID_INTR_FLICK_POWR global.PIXELGRID_INTR_FLICK_POWR
	#define PIXELGRID_INTR_DISABLE_Y  global.PIXELGRID_INTR_DISABLE_Y


	#define PIXELGRID_GAMMA_W           global.PIXELGRID_GAMMA_W
	
	#define DELTA_RENDER_FORCE_REFRESH global.DELTA_RENDER_FORCE_REFRESH
	#define DELTA_RENDER_CHECK_AREA    global.DELTA_RENDER_CHECK_AREA
	
	#define SERVICE1 global.SERVICE1
	#define SERVICE2 global.SERVICE2
