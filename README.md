# Koko-aio

Koko-aio shader is meant to be an all-in one crt shader.<br>
It can be configured with many parameters, so that can be
scaled to run on even on modest gpus while still developed to
run with heavier presets on at least Haswell+ iGpus.<br>
On that gpu, as in version 3.5, it reaches about 85fps with all features enabled<br>
When dealing with lowres content on 1920x1080 resolution.<br>
While it is not meant to simulate the internal behaviour of CRT displays,<br>
it aims to give users "visual" parameters to make their monitors look similar.<br>
Several presets are included.<br>

***Additional documentation:***
* [See here](docs-ng.md)

***Additional artwork:***
* https://github.com/kokoko3k/koko-aio-slang-presets-and-overlays

***Actually, it provides emulation/support for:***
* Color corrections (Gamma, contrast, saturation, luminance, vibrance, color temperature adjustments)
* B/W display "colorization"
* FXAA Antialiasing
* RF Noise
* Dedithering
* NTSC/PAL CVBS color bleeding and Artifacts
* Phosphor persistance
* Deconvergence
* Gaussian blurring/sharpening
* Phosphor Glow
* Tate mode
* Scanlines
* Interlacing
* Double scanning
* Multiple phosphors layout
* Aperture grille, slot mask, shadow mask.
* Moire mitigation strategies
* Dot martix with ghosting
* Haloing, Blooming
* Curvature
* Bezels with realistic reflections  (Thank you HyperspaceMadness for allowing me to rip his automagically generated bezel!)
* Background, Foreground and Backdrop images
* Ambient lighting with realistic illumination
* Vignette, spotlight
* Full screen glowing
* Integer Scaling 
* Tilting
* Light on power consumption 


***External code by:***
* Nvidia (FXAA)
        
# Examples from NG version

***Dynamic Ambient light examples***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/Amby-night.jpeg?raw=true)
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/Amby-day.jpeg?raw=true)
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/Amby-widen.jpeg?raw=true)

***Hires content***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/hires.jpeg?raw=true)

***Overmasked***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/Overmask,jpeg?raw=true)
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/Overmask2.jpeg?raw=true)

***Ntsc selective blurring and sharpening***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/sonic1.jpeg?raw=true)

***Antialiased***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/fxaa.jpeg?raw=true)

***Mask experiments***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/overlapped.jpeg?raw=true)
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/oldpainless.jpeg?raw=true)
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/pinchlook.jpeg?raw=true)
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/Wide-Mask?raw=true)

***ffmpeg player***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/tv.jpeg?raw=true)

***Handhelds***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/handhelds/gg_lights1.jpeg?raw=true)
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/handhelds/gg_ambilights.jpeg?raw=true)
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/handhelds/gmb_zoom.jpeg?raw=true)
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/handhelds/gbp.jpeg?raw=true)
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/handhelds/gbm_desktop.jpeg?raw=true)
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots-ng-1.0/handhelds/wario.jpeg?raw=true)


# Old screenshots from 3.5

***monitor-slotmask-bloom-bezelwider - Arcade - Final fight***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots.3.5/monitor-slotmask-bloom-bezelwider.mame.ffight.png?raw=true)

***monitor-Commodore_1084S-wider - Amiga - ProjectX SE***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots.3.5/monitor-Commodore_1084S-wider.puae.projectx.png?raw=true)

***tv-PAL-my-old - Master System - Trans Bot***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots.3.5/tv-PAL-my-old,mastersystem.transbot.png?raw=true)

***tv-NTSC-1 - Genesis - Sonic 2***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots.3.5/tv-NTSC-1.md.sonic2.png?raw=true)

***tv-NTSC-2 - Snes - Aladdin***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots.3.5/tv-NTSC-2.snes.aladdin.png?raw=true)

***tv-aperturegrille-bloom-bezel - Amiga - Leander***
![ ](https://github.com/kokoko3k/koko-aio-slang-misc/blob/main/screenshots/screenshots.3.5/tv-aperturegrille-bloom-bezel.puae.leander.png?raw=true)
