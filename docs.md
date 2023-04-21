**koko-aio-slang parameters documentation**

**Color corrections:**<br>
    Modify luminance, saturation, contrast, brightness and color temperature
    of the signal, at "input" stage.<br>
    Gamma correction is applied to the final processed picture.<br>
    It is also possible to emulate a monochrome display with custom colors:
    
        Monochrome screen colorization:
            The amount of (de) colorization applied.
        Hue bright, Hue dark:
            Set the hue for bright and dark colors.
        Hue bright-dark bias:
            Controls the distribution of dark and bright hues.
    
**FXAA:**<br>
    Apply the well known antialiasing effect by Nvidia.<br>
    Use it if you don't want to blur the image and you still don't like<br>
    jagged or too much pixelated images.<br>

**CVBS: NTSC color artifacts: **<br>
    Tries to emulate typical NTSC color artifacting without emulating<br>
    full NTSC coding/decoding pipeline.<br>
    While it improves the look of NTSC content, don't expect it to be<br>
    an accurate emulation (yet?)<br>
    As today, it is enough to emulate rainbowing effects on genesis.<br>
    
** RF Noise: **<br>
    Emulates radio frequency noise with a given strength<br>
    
**CVBS: Bandwidth limited chroma:**<br>
    Will cause an horizontal chroma bleed which cheaply mimics the effect of<br>
    poor composite video signals.<br>
    It can be used with RGB shifting and image blurring to give the picture<br>
    an ntsc look without dealing with specific encoding/decoding stuffs. <br>

**Deconvergence:**<br>
    Shift R,G,B components separately to mimic channel deconvergence.<br>
    By varying Red, Green and Blue offsets, the relative component will be<br>
    shifted column by column, row by row.<br>
    
**Glow/Blur:**<br>
    Emulate the CRT glowing "feature", so that the brighter areas of<br>
    the image will light their surroundings,<br>
    with options to switch to classic blur.<br>
    
    Input signal strength:
        The input signal gain
    Input gamma:
        Controls how much the signal has to be bright to produce the glow.
    Glow spread amount:
        The higher, the more the bright colors will smoothly expand.
        It emulates the natural antialiasing you see on CRTs on bright areas.
    Sharpness (horizontal, vertical):
        The lower, the blurrier the image.
        When set to zero, his value is handled using "Glow spread amount"
        When pushed to its maximum value, no blurring will occour.
    Glow / blur bias:
        Higher negative values -> more glow : brighter colors expands over darker ones.
        Higher positive values -> means blur: all the colors are blurred.
        0.0 means no blur, no glow.
    Blur NTSC artifacts more
        When NTSC artifacts emulation is enabled, this option will let you blur
        them more, this would help to selectively blur things like waterfalls
        in Sonic 2.
        The value you set it will be subtracted from glow horizontal sharpness.
    Blur less NTSC artifacts (min treshold)
        In relation to the previous setting, this allow to blur only the most
        prominent artifacts.
    Show NTSC artifacts mask (debug)
        This will help you to set the previous 2 values as it will show only
        the artifacts that will modify the blur.
    
**Masks and/or Darklines:**<br>
    Emulates CRT RGB phosphors (RGB Mask),<br>
    slotmasks and aperturegrille (Darklines).
    
    (HiDPI) Vmask and Darklines multiplier:
        This shader is tuned for 1080p, but ff you have an HiDPI display
        you may want to scale this filter by a factor.
    Vmask Strength:
        How much will the RGB mask be visible.
    . (LoDPI) Green,Magenta -> RGB:
        By exploiting common monitors RGB subpixel order, this causes
        the RGB mask, to be emulated by using just 2 pixels instead of 3.
        Very useful for 1080p (or lower) displays and to keep more brightness.
        If you have reddish tint, please double check that your monitor is
        running at native resolution and the operating system is not scaling
        the screen.
        This option is disabled if a vertical game is detected 
        (mame 2003 plus and fbneo cores)
    . Horizontal Gap between triads:
        In real displays, rgb triads are separated by a black space.
        You can emulate it by turning this feature on.
    . Affect bright colors:
        Emulating RGB masks will lower the resulting image brightness and you
        cant just push input signal brightness without clipping the signal.
        By using this option, the RGB mask will be less evident on brighter
        colors.
        However, it is advised to use the "Halo" feature instead (see later)
        ft your system can handle it.
    Darklines: strength:
        How much will the horizontal darklines be visible.
    . Triad offset:
        When drawing "straight" horizontal darklines, you can emulate CRT aperture grille.
        But if you want slotmasks instead, you need to vertically
        offset them every RGB triad.
        However, slotmask emulation can be enabled via a superior implementation
        if you enable scanlines (see below).
    . Triad height:
        Basically tells the shader how much a triad has to be high.
    Darklines: affect bright colors:
        See "RGB Mask: affect bright colors"

**Tate mode:**<br>
    Rotates mask and scanlines by 90°<br>
    
**Scanlines:**<br>
    Emulate CRT scanlines.<br>
    
    Scanlines gap brightness:
        controls how "little" they will look pronunced.
        You can even use a negative value to make the scanline more evident,
        but graphical glitches may occour.
    Minimum/Maximum height:
        Control the scanline thickness, can be used to mitigate moiree.
    Min->Max Inertia
        The lower, the thinner scanlines will be used for higher brightness.
    Scanlines bleeding:
        Will cause the scanline itself to light the scanline gap (dark) part. 
        You may use it to keep a good picture brightness level.
    Interlace flicker:
        Emulates the flickering issues present on crt interlaced screens
        where the brighter lines flickers when they are near dark ones.
        You can choose to produce the flickering: never, always or only
        when the input picture is considered interlaced.
        The threshold for that is defined in config.inc 
        with the parameter: MIN\_LINES\_INTERLACED.
    Disable on interlaced screen:
        You can choose to completely disable scanline emulation when
        the input picture is considered interlaced.
    Slotmask type (don't use with darklines!)
        You may want to draw slotmasks alongside the scanlines to sync their heights
        and avoid graphical glitches.
        If you enable this feature, it is highly recommended to disable darklines.
        Darklines will still used when dealing with interlaced or flickering screens.
        Type 1 allows you to configure strength and stagger.
               The stagger height will be modulated by the scanline height.
        Type 2 produces thinner slotmasks, (dark gaps more pronunced),
               but with fixed offset.
               The stagger height will still be modulated by the scanline height.
               This is intended to give pixels a sparkling point.
               Works best with scanline heights in range [0.5..0.7] 
        Type 3 is fixed and produces heavier and thinner slotmasks without visible scanlines.
    Slotmask strength
        The strength of the slotmask
    . Offset
        This is the slotmask offset/stagger, (available on type 1 only)
        Keep it around 79 or all the way to max

**Dot matrix emulation:**<br>
    Emulates low refresh "boxed" screens used in old handheld consoles.<br>
    
    Grid strength:
        How much the grid is visible.
    Grid sharpness: 
        Modulates the thickness of the grid around cells.
    Strength on background:
        How much should the grid be visible on background?
        More positive values -> more grid on bright
        More negative values -> more grid on dark
    Gap brightness:
        You may want to use a white grid eg: for gameboy mono emulation.
    RGB strength:
        Emulate rgb subpixels (Set 0.0 for BW display)
    RGB sharpness:
        Low values will gradually blend subpixels.<br>
        You may want to lower this value to cancel vertical artifacts.<br>
    Green gain correction:
        R and B cnahhels could be partially cancelled by the grid around.<br>
        Lower this if the image looks green.<br>
    Refresh inertia:
        Emulates a low refresh screen, set the power of the effect.<br>
    Inertia on:
        0: display is always slow to refresh
        1: display is slow to refresh bright pixels
        2: display is slow to refresh dark pixels
        
**Halo:**<br>
    Emulates the effect of the brighter pixels reflected by the CRT glass<br>
    that lights nearby zones (a sort of tight bloom).<br>
    The light is meant to be spreaded in a way that it nulls the effect of the<br>
    dark scanline parts, darklines and the RGB masks.<br>
    So you can use this to restore the brightness and color saturation<br>
    loss when using features like scanlines, darklines or RGB masks.<br>
    
	Light up scanlines too:
		Theoretically Halo have to be applied 
		"over" everything, because that is the way it works in nature.
		But you can choose to cheat and instead apply scanlines over the halo
		instead.
		Do this if you like much more pronunced scanlines, even at the
		price of some graphical artifacts visible on high contrasted areas. 

    Refer to "Glowing Input/power" for other parameters meaning.
    
**Bloom:**<br>
    Acts like Halo, but affects a much wider area and is more configurable.<br>
    By using this effect and playing with its parameters, you can achieve funny<br>
    or even artistic results.<br>
    
    Final mix:
        Modulates between the original images and the bloomed one.
    Radius:
        Controls how much the bloom has to be wide.
    Quality:
        How much the shape of the bloomed picture will reflect the original one.
    Input Gamma (threshold):
        Use this as a threshold to control how much a pixel has to be bright
        to produce a bloom effect.
    Output Gamma (contour smoothness):
        Lowering it will make the bloom contour more pronunced.
        Handy to simulate well defined "Aura" effects.
    Power multiplier:
        Just apply a gain to the final bloom.
    Modulate: Local exposure eye adaption strength
        Simulate the process through which the pupil adapt itself to different
        light conditions.
    Modulate: Strength on bright areas (0 = aura)
        Since the light produced by the bloom effect is added to the underlying
        image, it can produce clipping effects on the already bright areas.
        This is actually an hack that will avoid to bloom them.
    Bypass/Solo:
        See how the bloomed image looks alone.
        Use 1.0 to see naked bloom without any modulation applied
        Use 2.0 to see naked bloom with modulation applied 

**Curvature:**<br>
    Emulates a curved CRT display.<br>
    
    WARP X, WARP Y:
        control how much the display is curved along its axes.
    Corner radius, Corner sharpness:
        Control the "smoothness" of the display corners.
    Cut curvature ears;
        If you see weird image repetition try this.
        
**Bezel:**<br>
    Draws a monitor frame with simulated reflections from the game content.<br>
    The monitor frame is an image loaded by the shader and is shipped<br>
    in the "textures" shader subdirectory, named "monitor\_body.png"<br>
    It has been made with the following rules that may come handy<br>
    only if you want to edit it; otherwise go on.<br>
    - The red channel represents the luminance information<br>
    - The green channel represents the highlights<br>
    - The alpha channel in the inner frame represents the part of the bezel<br>
      that will be filled by the game content<br>
    - The blue channel represents the part of the bezel that will be filled by the game reflection.<br>
    
    Straight
        Use a straight bezel instead of a curved one.
    Inner zoom:
        Allows to shrink or expand the game content to fit the monitor frame.
        When integer scaling is enabled, this is ignored.
    Frame zoom:
          Allows to shrink or expand the monitor frame to fit the game content.
    Bezel color (red,green,blue) and contrast:
        Allows to choose the color of the monitor frame.
    Reflections strength
        The amount of reflections
    Reflections sharpness
        Modulates from totally blurred to totally sharp reflection appearance.
    Reflections roughness
        The amount of material roughness in reflection area
    Diffusion strength
        Mix an amount of high blurred reflection to simulate light diffusion
    Specularity strength
        The amount of specular reflection
    Darken corners
        How much the bezel corners should be darkened
    

**Backgound image:**<br>
    Draws an image on screen picked from the "textures" shader subdirectory,<br>
    named: background.png<br><br>
    **-> It is needed that you set retroarch aspect to "Full" <-**<br>
    ( Settings, Video, Scaling, Aspect Ratio = Full )<br>
    The image is painted "under" the game content and under the monitor frame by<br>
    default, and his alpha channel will let you see ambient lighs (see next).<br>

    Image over content (alpha channel driven)?:
        ...however you can paint the image over the game content and over the
        monitor frame itself by selecting this option.
        If you do so, the alpha channel of the background image will be used to
        let you view the underlying content.
    Shift(Zoom) Image over X(Y) axis:
        move or zoom the whole background image.
    Rotate image mode
        This could be needed when dealing with vertical games.
        Use -1 to let the shader try to guess if the rotation is needed.
    Wrap mode:
        This feature is static, to use it 
        you have to manually enable it by removing the leading: "//"
        from "//#define ALLOW_BG_IMAGE_TEXTURE_WRAP_IN_SHADER" in config.inc
        
        What to do outside the image:
        0  Mirrored repeat because so is configured in main .slangp.
        1  Clamp to border and it means black.
        2  Clamp to edge and means that it repeats the edge color.
        3  Plain repeat without mirroring.

        
**Backdrop support:**<br>
    Some old arcades used a mirror trick to overlay the<br>
    game content over an high definition printed image.<br>
    The image used by default, picked from the "textures" shader subdirectory,<br>
    is named: boothill.jpg<br>
    
        Shift(Zoom) Backdrop over X(Y) axis:
            move or zoom the whole background image.
    
        
**Ambient light leds:**<br>
    Emulates the presence of led strips under the monitor that lights the<br>
    surroundings according to the edges of the game content.<br>
    **-> It is needed that you set retroarch aspect to "Full" <-**<br>
    ( Settings, Video, Scaling, Aspect Ratio = Full )<br>
    
    Slowness: 
        How much will the leds will take to reflect the game content.
        It may sound silly to make them slow, but if they reacts too fast,
        they may distract you.
        Keep in mynd that there is a scene detection logic that will make them
        react as fast as possible when a scene change is detected.
    Light Falloff:
        How wide is the area illuminated.
    Led power:
        Leds post gain.
        Note: To avoid burn-in effects, keep Light Falloff + Led power not too high.
    Colorize Bezel
        Allow to add an amount of the ambient light over the bezel frame
    Colorization size
        How much the ambient light should bleed over the monitor.
        Pushing this too high would make it bleed over the tube.
        This is not supported.
    Back/Foreground image alpha blend
        When displaying background or foreground images, ambient lights are
        shown on their transparent areas (alpha channel)
        Switching this you can choose if you want to emulate leds:
        under the image (0/mix) or over the image (1/add)
    Always colorize Back/Foreground image (add mode only)
        When "Back/Foreground image alpha blend" is set to 1/add,
        you can choose to always colorize the foreground image by a certain amount.
        This can be used to produce big haloes all around the tube.
        This internally works by adding the amount of your choice to the alpha channel
        of the foreground image.
        
**Luminosity dependant zoom:**<br>
    On older CRT monitors, the picture gets bigger when the image was brighter.<br>

**Vignette:**<br>
    Will cause uneven brightness of the image, more at the center,<br>
    less at the edges.<br>
    
**Spot:**<br>
    Simulates external light reflected by the monitor glass.<br>
            
**Aspect Ratio:**<br>
    When using effects that need Retroarch aspect ratio option<br>
    to be set to "full", you have to provide the source aspect<br>
    ratio to the shader.<br>
    Use -6 for MAME cores that pre-rotates the game (TATE mode)<br>
    With Mame 2003 plus and fbneo cores, koko-aio detects if the<br>
    game is rotated or not without any user intervention.<br>
    
    Aspect Ratio Numerator:
        Setting non positive value here will switch to a predefined
        aspect ratio from the following list:
        0  = 1.33 MAME
        -1 = 1.55 NTSC
        -2 = 1.25 PAL
        -3 = 8/7  Snes
        -4 = 10/7 Megadrive 
        -5 = Uncorrected
        -6 = 0.75 MAME rotated 1.33 games in TATE mode
    Aspect Ratio Denominator:
        As long as Aspect Ratio Numerator is positive, this will
        be used as the denominator of the fraction.

**Global shift/zoom image:**<br>
    Zoom and shift everything on screen, but background pictures.<br>

**Override content geometry:**<br>
    Contrary to the global aspect ratio control, this changes only the game geometry.<br>
    Bezel stays the same.<br>
    
    Integer scale: Game content zoom height is rounded to nearest integer.
    Maximum integer scale: Dont allow integer scaling more than this
                     * beware: the following options in this group
                       overrides the integer scale.
    Aspect: Change aspect ratio.
    Vertical/Horizontal position: Shifts the game position
    Zoom: Change the size

**Tilt:**<br>
    Put the bezel and the game content into perspective.<br>
    The implementation is basic, you can expect correct<br>
    results when tilting alongside a single axis or when<br>
    using both, but with small values.<br>
    
    Tilt along X(Y) axis:
        Rotate the image in space
    Fov: Modulates the field of view
    Bezel multiplier:
        Can be used to adjust the bezel rotation
        in relation to the game tilt amount
    
    
**Alternate line blanking:**<br>
    CRT monitors \*real\* refresh was amazing, today is just "meh" in most cases.<br>
    This emulates the low pixel persistance of CRT monitors <br>
    and reduces the motion blur, typical of LCD displays, by blanking even/odd<br>
    screen lines on even/odd frames, by sacrificing image brightness, ofc.<br>
    
    This feature is static, to use it 
    you have to manually enable it by removing the leading: "//"
    from "//#define ALLOW_ALT_BLANK" in config.inc
    
    Frame insertion strength:
        How much the line will be blanked.
    Dark lines period:
        You can blank single line or a group of them at once.
        See what performs better on your display.






