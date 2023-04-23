**parameters documentation**

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
    Aspect Ratio Denominator:
        As long as Aspect Ratio Numerator is positive, this will
        be used as the denominator of the fraction.

**Override content geometry:**<br>
    Contrary to the global aspect ratio control, this changes only the game geometry.<br>
    Bezel stays the same.<br>
    
    Integer scale: Game content zoom height is rounded to nearest integer.
    Maximum integer scale: Dont allow integer scaling more than this
