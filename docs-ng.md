**koko-aio-slang parameters documentation**

**Color corrections:**<br>
    Modify luminance, saturation, contrast, brightness and color temperature
    of the signal, at "input" stage.<br>
    Gamma in correction is applied at ti beginning of the chain,<br>
    Gamma out correction is applied to the final processed picture.<br>
    Input signal gain is applied in the chain just before the crt emulation stages.<br>
    
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

** RF Noise: **<br>
    Emulates radio frequency noise with a given strength<br>
    
**CVBS: NTSC color artifacts: **<br>
    Tries to emulate typical NTSC color artifacting without emulating<br>
    full NTSC coding/decoding pipeline.<br>
    While it improves the look of NTSC content, don't expect it to be<br>
    an accurate emulation (yet?)<br>
    As today, it is enough to emulate rainbowing effects on genesis.<br>
    If you enable Glow/Blur functions or Bandwidth limited chroma,<br>
    the image will be blurred in a way or another.<br>
    You can selectively keep the part of the image which does not contain<br>
    artifacts sharp by using the followin controls.<br>
    This allow to selectively blend artifacts.

    Consider artifacts above this treshold:
        Tune this to select more or less artifacts, depending on their strength.
    Show the mask of selected artifacts (debug)
        This will show only the part of the image that contains artifacts.
        Use it to for a better visual feedback of the following parameters

    1* Under treshold: Cancel blur (Glow)
        How much the glow/blur function will skip blurring "unartifacted" areas.
    2* Under treshold: Cancel Bandwidth limited chroma
        How much the Bandwidth limited chroma function will skip blurring 
        "unartifacted" areas.
    3* Under treshold: Cancel artifacts
        How much the artifacts under the treshold will be completely removed.
    
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
    
    Glow to blur bias:
        Higher negative values -> more glow : brighter colors expands over darker ones.
        Higher positive values -> means blur: all the colors are blurred.
        0.0 means no blur, no glow.
    Glow spread amount:
        The higher, the more the bright colors will smoothly expand.
        It emulates the natural antialiasing you see on CRTs on bright areas.
        More pronunced as "Glow to blur bias" approaches 0.
        
    Sharpness (horizontal, vertical):
        Modulates the sharpness of the image.
        - Max (actually 7.0) will not alter the image sharpness.
        - More than 0: will use gauss blur
        - Less than 0: will use box blur and will progressively
          add visual sharpness to image when approaching lower values.

**Tate mode:**<br>
    Rotates mask and scanlines by 90°<br>
        
**Low level phosphor grid**<br>
    This is a way to produce horizontal masks, scanlines and aperturegrille/slotmasks.<br>
    Parameters are tricky to setup, but possibilities are mny more quality is good at 1080p<br>
    and hopefully great at higher resolutions.<br>
    By reading the following explanaitions, you will realize that this section can also be used to emulate<br>
    handhelds screens, where pixels you see on screen have to be sized proportionally to the game one.<br>
    
    Overmask (1.0 = neutral):
        Values > 1.0 give a gritty/gariny look to the whole mask.
          It may cause moiree if combined with curvature, dedot, or sparkling look punch.
        Values < 1.0 tend to nullify the whole mask effect.
        
    
    Horizontal mask (rgb subpixel mask strength)
        X resolution: (core or screen) (**):
            0: Phosphors width will be relative to the pixel width of the core (game).
            1: Phosphors width will be relative to the pixel width of the screen.
        Mask type preset:
            You can have the shader generate a preconfigured mask for you:
            1:gm 2:gmx 3:rgb 4:rgbx 5:rbg 6:rbgx 7:wx
            1:GreenMagenta, 2:GreenMagentaGap, 3:RedGreenBlue, 4:RedGreenBlueGap, 5:RedBlueGreen, 6:RedBlueGreenGap
            7:WhiteGap (means r,g and b phosphors are completely overlapped, nice with scanline deconvergence)
            
            (beware that due to limitations of the actual implementation, masks ending in "x")
            works reliable when emulating slotmasks only at screen coordinates with multiplier = 1.0)
            bh selecting preset = 0, you can draft your own by using the following knobs:
                Phosphors+gap count (mask size):
                    How much phosphors or blank spaces the final mask will have.
                R,G,B, Phosphor position:
                    The position of every phosphor.
                Example 1: Phosphors+gap count=4 and R=0 G=1 B=2
                ...will give you a mask with red,green,blue and a blank space.
                Example 2: Phosphors+gap count=2 and R=1 G=0 B=1
                ...will give a mask with green + a mix of blue and red (magenta)
                Example 3: Phosphors+gap count=3 and R=1 G=1 B=1
                ...will give a mask with a blank space, the neutral white color and another blank space
                Example 4: Phosphors+gap count=1 and R=0 G=0 B=0
                ...like the previous one, but without any blank spaces.
        Phosphors width Min, Max:
            The width of each phosphors can grow or shrink, depending on the
            luminosity of the underlying pixel luminance.
            1.0 refers to the full mask width, so stay around 0.2 if you want
            avoid them to blend.
            Use Min and Max parameter to limit the minimum and maximum size
            they can reach.
        Phosphors width min->max gamma:
                Since emulating phosphors with high Min-Max range changes the apparent gamma of the final image,
                it is advised, if needed, to use this option to compensate, instead of the main gamma correction.
                It is also a quick way to make the image brighter or darker.
        Cell size multiplier x (neg=divider):
            Multiply (or divide if the parameter is < 0) the mask (cell) size by a factor.
            As stated(**), the size may be relative to screen or core, this allow you to
            "zoom" the cell horizontally and can be useful if you have an HiDPI screen.
            For example, you may choose to use screen sized masks and zoom them by a factor
            of 2 or 3 to make room for phosphors and see them visually grow in width.
            Likewise, you can use core/game(**) sized masks and divide them by a factor
            if they appears too big.
        Inter-cell extra steepness (for integer scaling)
            When you set maximum width/height to anything > 0.5, the phosphor light will bleed over
            the adiacent (left/right up/down) one so that they will start to blend togheter.
            This option will avoid the bleeding.
            You may want them to merge or not, depending on your preference to see a visible "grid"/lines.
            This function is useful when you want to emulate handhelds screens using integer scaling, 
            where cells are well separated.
        Black level of the unexcided phosphor grid
            Draw the vertical grid that hosts phosphors.
            This is likely to produce moiree when using X resolution = core
            
            
    Scanlines (*4)
            Scanlines emulation, set the strength of the effect here.
        Phosphors height Min, Max:
            Try to keep scanline height between those values, depending on content brightness.
        Phosphors width min->max gamma:
            Since emulating phosphors with high Min-Max range changes the apparent gamma of the final image,
            it is advised, if needed, to use this option to compensate, instead of the main gamma correction.
            It is also a quick way to make the image brighter or darker.
        Slotmask(-fake) offset(*):
            This will cause every cell to be vertically shifted by the configured amount to
            emulate a slotmask phosphors layout.
            It is true that for accurate reproduction of them, slotmasks are commonly emulated
            at screen size, but this causes, on low resolution displays, weird artifacts,
            primarily when using curvature and when you try to draw scanlines -and- slotmasks.
            Here there is an added value given by the fact that the shift itself
            can be relative to not only to the screen pixel height, but to game pixel height. (**)
            By selecting Y resolution=0 (so core coordinates**) and enabling this slotmask offset,
            you will have a staggered scanline.
            This allows you to not drawing a scanline -and- a slotmask, but to draw a "slotmasked"
            scanline.
            While this does not exist at all in crt technology, it greatly mitigates the artifacts
            just explained while producing a fairly convincing effect, very similar to a screen
            with visible scanlines and visible slotmask.
        Inter-cell extra steepness (for integer scaling)
            When you set maximum width/height to anything > 0.5, the phosphor light will bleed over
            the adiacent (left/right up/down) one so that they will start to blend togheter.
            This option will avoid the bleeding.
            You may want them to merge or not, depending on your preference to see a visible "grid"/lines.
            This function is useful when you want to emulate handhelds screens using integer scaling, 
            where cells are well separated.
        Dedot mask between scanlines
            When using Horizontal masks, you mai notice a disturbing dot pattern left between high
            scanlines, that's the residual of horizontal mask.
            Use this parameter to clear it and use it only if needed or it would have counter-effects.
            Also, mutating dots to straight lines would make moiree more visible when using curvature.
        Deconvergence Y: R,G,B phosphor" 
            This emulates Y deconvergence on phosphor level rather than on image level as seen in
            the previous deconvergence section.
            Emulating deconvergence here is good because phosphors will be able to brighten the
            dark gap left by scanlines.
        
        
    Interlace detect + Scanline alternate above # lines:
        koko-aio will mark a frame as interlaced and will alternate odd/even scanlines
        at odd/even frames when the number or lines is above the configured value.
    Disable on interlaced screen:
        You may want to avoid drawing scanlines gaps when interlaced content is found
    Interlace Flicker (0=off,1=on,2=if interlaced):
        Since we can emulate scanline appearence, here we deal with interlaced content too.
        This setting emulates the flickering issues present on crt interlaced screens
        where the brighter lines flickers when they are near dark ones.
        You can choose to produce the flickering: never, always or only 
        when the input picture is considered interlaced.
        The threshold for that is defined in config.inc with the parameter: MIN\_LINES\_INTERLACED.
    Interlace Flicker power: The strength of the effect.

    
    Vertical cell Mask:
        The shape of the mask generated ny this function is "boxed", while the one
        generated by the previous function ("scanlines or vertical mask1") is more rounded.
        Phosphor masks are usually vertically delimited by thin lines.
        This parameter will set the visibility of them.

        Resolution: (core or screen) (*1)
            Should the vertical interval (height) between those likes be relative to screen or core pixel size?
        Height divider (neg=multiplier) (*2):
            The more, the less that intervall will be.
            Interesting values for screen resolution: 1.0, 0.75, 0.5
        Fadeout under light: How much they will be visible over bright pixels.
        Even/odd offset (slotmask) (*3):
            If you not used, the previous section to emulate scanlines(*), but still want to emulate
            slotmasks layouts, you can set this to 1.0.
            You can draw slotmasks at screen coordinates to emulate real crts or choose to paint
            them at core coordinates to have a more defined slotmask
            ...if you like slotmasks so much :-)
        Vertical shift (for use with core resolution):
            This parameter allows you to move the whole vertical mask along the Y axis.
            It is intended to be used with core resolution(*1) and integer divider/multiplier(*2)
            to clear weird patterns from the screen when using slotmasks (*3) alongside scanline emulation (*4).
        Steepness: 
            The more, the thinner they will be.
            Setting this to very high values, may make them disappear unevenly.
        Sparkling look punch:
            Makes the "Vertical cell Mask" effect more pronunced and "pinchy/Sparky" by highering its contrast.
            Beware, this may produce moiree.


**Dot matrix emulation:**<br>
    Emulates low refresh "boxed" screens used in old handheld consoles.<br>
    
    Grid strength: How much the grid is visible.
        Gap brightness:
            You may want to use a white grid eg: for gameboy mono emulation.
        Grid sharpness: 
            Modulates the thickness of the grid around cells.
        Paint on bright:
            How much should the grid be visible on background?
            More positive values -> more grid on bright
            More negative values -> more grid on dark
    Refresh inertia:
        Emulates a low refresh screen, set the power of the effect.<br>
        Inertia on:
            0: display is always slow to refresh
            1: display is slow to refresh bright pixels
            2: display is slow to refresh dark pixels
    Shadow strength:
        Emulates the typical shadow seen on Gameboy mono handhelds
        casted by on the underlying screen.
        Shadow offset:
            Moves the shadow left or right.
        
**Halo:**<br>
    Emulates the effect of the brighter pixels reflected by the CRT glass<br>
    that lights nearby zones (a sort of tight bloom).<br>
    The light is meant to be spreaded in a way that it nulls the effect of the<br>
    dark scanline parts, darklines and the RGB masks.<br>
    So you can use this to restore the brightness and color saturation<br>
    loss when using features like scanlines, darklines or RGB masks.<br>
    
    Pre-attenuate input signal gain to 1x:
        Nullifies the input gain applied in the color correction section.
        This way the halo effect will be consistent and will not depend on 
        it, avoiding hard to manage cascading effects.
    Strength (negative = 10x precision)
        The effect strength.
        Negative values are interpreted as positive ones, divided by 10,
        when fine tuning is needed.
    Sharpness
        The lower, the wider the halo.
    Gamma in
        Act like a soft treshold; the higher, the less the darker colors
        will be "haloed"
    Gamma out
        Post-gamma correction applied to the halo.
    Light up scanline gaps and dot grid gaps too:
		Theoretically Halo have to be applied 
		"over" everything, because that is the way it works in nature.
		But you can choose to cheat and instead apply scanlines over the halo
		instead.
		Do this if you like much more pronunced scanlines, even at the
		price of some graphical artifacts visible on high contrasted areas.
		The same apply for the grid emulated via dot matrix emulation feature.
 
    
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
        "Fitting the monitor frame" is the ONLY scope of this option.
        To have a smaller or larger than bezel screen, please use "Override content geometry"
        options, or the reflections on the bezel will be misaligned.p

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
    Emulates the presence of led strips behind the monitor that lights the<br>
    surroundings according to the edges of the game content.<br>
    **-> It is needed that you set retroarch aspect to "Full" <-**<br>
    ( Settings, Video, Scaling, Aspect Ratio = Full )<br>
    
    Slowness: 
        How much will the leds will take to reflect the game content.
        It may sound silly to make them slow, but if they reacts too fast,
        they may distract you.
        Keep in mynd that there is a scene detection logic that will make them
        react as fast as possible when a scene change is detected.
    Led power/Falloff:
        How input gain is applied to a single led, affects light wideness.
    Led saturation:
        Leds saturation post gain.      
    Led internalness:
        The distance between the virtual led strip and the content.
        High values will move leds behind it, while lower values will move
        leds around it.
    Widen lights:
        Dumb stretch of the visible texture, operates on the whole content, instead of the
        single led.
        Note: To avoid burn-in effects, keep Light Falloff + Led power not too high.
    Colorize Bezel;
        Allow to add an amount of the ambient light over the bezel frame
    Colorization size:
        How much the ambient light should bleed over the monitor.
        Pushing this too high would make it bleed over the tube.
        This is not supported.
    Back/Foreground image alpha blend:
        When displaying background or foreground images, ambient lights are
        shown on their transparent areas (alpha channel)
        Switching this you can choose if you want to emulate leds:
        under the image (0/mix) or over the image (1/add)
    Foggy (power on dark colors, add mode only)
        When using add mode or when colorizing the bezel via led lights, you may want
        to lessen the foggy effect to turn it into a more realistic illumination.
        Think to this as a way to turn the light target from the spectator (foggy)
        to the background (not foggy).
    Always colorize Back/Foreground image (add mode only)
        When "Back/Foreground image alpha blend" is set to 1/add,
        you can choose to always colorize the foreground image by a certain amount.
        This can be used to produce big haloes all around the tube.
        This internally works by adding the amount of your choice to the alpha channel
        of the foreground image.
        
**Luminosity tied zoom:**<br>
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
    
    Integer scale:
        Game content zoom height is rounded to nearest integer.
    Maximum integer scale: 
        Dont allow integer scaling more than this
        * beware: the following options in this group overrides the integer scale.
    Aspect:
        Change aspect ratio.
    Vertical/Horizontal position:
        Shifts the game position
    Zoom: 
        Change the size
    Sharp fix through offset:
        When using integer scaling, it may be not possible to
        draw sharp rounded lines.
        This hack add a small (the higher, the smaller) offset
        to the image that allow for sharp lines at the cost of a slightly
        lower draw precision. Use 0.0 to disable the hack.
    

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
        
**Delta Render:**
    Koko-aio can render only the part of the screen that has been changed,<br>
    leading to a measurable power consumption reduction.<br>
    This feature can, however, produce artifacts in some cases, so the feature<br>
    is statically disabled by default by now.<br>
    To use it, you have to manually switch, in file config.inc: <br>
    #define DELTA_RENDER 0.0 <br>
    to <br>
    #define DELTA_RENDER 1.0 <br>
    
    Force refresh interval:
        Forces a full screen refresh every #number of frames;
        if there was artifacts on the screen, they will be cleared.
        Power comsumption benefits will be lower.
    Delta render area size
        If you see artifacts, try to make this higher.
        Artifacts come basically from bloom.
        By highering this value, Delta render can take higher blur radiouses
        into account.
        Power comsumption benefits will be lower.
    
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






