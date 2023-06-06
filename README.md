# Koko-aio Fork for Arcade Artwork (currently FinalBurn Neo and MAME 2003/2003plus)

Repository for game-specific Arcade Artwork by using the Koko-aio slang shader. Successfully tested under MacOS, Windows and iPadOS. Currently the Koko-aio shader provides superior performance on all reasonably powered desktops (including Macs), while providing enhanced shader functions, including bezel reflections,halo/glow effects and many more. It embeds game-specific artwork seamlessly and scales according to resolution. The koko-aio shader is currently under steady development, thus it is a clear aim to stay in line with the Upstream changes.<br>
<br>
Main source of this artwork comes from John Merrit, who set a benchmark for realistic arcade artwork. I still very much like them, and they shine even more in combination with Koko-aio. My selection of the artwork is arbitrary, but I try to publish eye candys earlier :-). Version 0.2 and following releases see the inclusion of some breathtaking 4K artwork provided by Ars Invictus.<br>
<br>
Requirements: RetroArch 1.5.0 or a newer RetroArch Nightly Build that support Vulkan. Tested with FinalBurn Neo (mainly) and MAME 2003/2003plus. MAME (current) now works out of the box, as the rotation of this core has been adjusted. Having said that, the MAME (current) core is still buggy for me.<br>
<br>
Update June 2023: I have successfully moved this repository to the 'ng' shaders that provide another quality increase. Until release 0.4, I would like to nightify all presets to the extent required. This release will also see usage of the new ambilight functionalities, if it makes sense. So stay tuned.
<br>
# Release 0.3 contains 52 game-specific presets - download here!
Backdrop games and 4k artwork included in this release.
Please see the list of game presets in the Release Notes.

# Screenshots
Screenshots are taken under MacOS with HDR enabled.

<img width="750" alt="Bildschirmfoto 2023-04-08 um 21 03 47" src="https://user-images.githubusercontent.com/24915559/230785582-e364fa18-e0ea-4908-a912-c3de18bfe70c.png">

<img width="750" alt="Bildschirmfoto 2023-04-09 um 17 59 40" src="https://user-images.githubusercontent.com/24915559/230785603-ef7b0491-3081-4075-b29d-3b6dc62a9aed.png">


Shots from v 0.2 and 0.3:<br>

<img width="851" alt="Bildschirm­foto 2023-03-25 um 22 34 39" src="https://user-images.githubusercontent.com/24915559/227745111-e03e33dc-adc4-400f-ab1e-195c959a7565.png">
<img width="851" alt="Bildschirm­foto 2023-03-25 um 22 32 36" src="https://user-images.githubusercontent.com/24915559/227745132-69501af9-19c0-4990-9e9c-c0e59276b073.png">
<img width="851" alt="Bildschirm­foto 2023-03-25 um 22 30 07" src="https://user-images.githubusercontent.com/24915559/227745148-43338ee5-3d77-4db5-b35a-02755ce52bdf.png">
<img width="851" alt="Bildschirm­foto 2023-03-25 um 22 29 12" src="https://user-images.githubusercontent.com/24915559/227745178-9f5948c3-cf38-4d77-b5f6-ca394020a472.png">
<img width="851" alt="Bildschirm­foto 2023-03-25 um 22 31 11" src="https://user-images.githubusercontent.com/24915559/227745159-bad3ff85-e90e-443d-8ce0-8c75fbdf7307.png">
<img width="851" alt="Bildschirm­foto 2023-03-25 um 22 33 41" src="https://user-images.githubusercontent.com/24915559/227745243-2af41d24-edeb-4e2d-a22e-55a2ee665a98.png">
<br>
Shots from v 0.1:<br>

<img width="512" alt="1943" src="https://user-images.githubusercontent.com/24915559/215357835-23de575f-66ba-477c-be39-e8ab433a8e50.png">
<img width="512" alt="aliensyn" src="https://user-images.githubusercontent.com/24915559/215357862-535b6e7e-dff0-4a86-9d86-f9a88f89921c.png">
<img width="512" alt="mpatrol" src="https://user-images.githubusercontent.com/24915559/215357897-803ccc6a-6bfa-4ef2-8b58-4547b140c5e3.png">
<br>

# Easy install

Step 1: Take the entire zip package as provided in the Release section and replace the koko-aio folder that comes with RetroArch: /shaders/shaders_slang/bezel/koko-aio; for the backdrop presets, the parallel version of koko-aio-backdrops is *as of v 0.3 no longer* required!!!<br>
Step 2: Move all .slangp-presets to the respective core configuration directory, i.e. /config/FinalBurn Neo/ and/or /config/Mame 2003 (0.78) and/or /config/MAME 2003-plus; with this, the right artwork launches automatically<br>
<br>
Note: The FinalBurn Neo.cfg/Mame 2003 (0.78).cfg/MAME 2003-plus.cfg files contain just one line that secures that the Aspect Ratio is set to 'Full'. Without this option, the background will not appear.<br>

# Dedicated install of only the additional Arcade Artwork

If you want to stay with koko-aio for some reason:
Step 1: Take the entire folder /textures/arcade_textures and move it locally to /shaders/shaders_slang/bezel/koko-aio/textures.<br>
Step 2: Move the content of the directory koko-aio/presets/arcade-koko-aio to /config/FinalBurn Neo/ and/or /config/Mame 2003 (0.78) -> by this, the game launches the right shader configuration automatically.<br>
<br>
Please also refer to the instructions contained in the ReadMe.md of these folders.<br>

# Manual installation from the Github repository

Please note that the koko-aio github repository has a different folder structure than RetroArch. In order to make a GitHub clone work, you must move all .slang presets from the presets directory one level up. Then you must adjust the reference in the two BASE presets, so that these BASE presets refer to the same directory, and you are ready to go.
<br>

# Further clones of the same game

Please see the Moon Patrol example - you can just duplicate the .slangp preset and rename it with the name of the clone. By this, you have an identical configuration for a clone. <br>

# Backdrop support

With latest Github (30 March 2023) and Release 0.3, backdrop support landed in koko-aio as a dynamic option. A separate shader repository is no longer required, and I have merged the backdrop presets into koko-aio - this is a great simplification for backdrops. 

# Technical Information

This fork will remain as closely as possible in line with the main repository, as I frequently update from Upstream. Here is a list of deviations from Upstream:
- koko-aio.slangp - line 43:  bg_under_wrap_mode = "clamp_to_border" (instead of "mirrored_repeat")
- koko-aio.slangp - line 48:  bg_over_wrap_mode = "clamp_to_border" (instead of "mirrored_repeat")
These changes are beneficial for this repository, as a mirrored repeat looks very strange for realistic cabinet backgrounds/foregrounds.

LEGACY no longer required as of April 2023, just for documentation: 
/shaders/config.inc - line 130: ALLOW_BG_IMAGE_TEXTURE_WRAP_IN_SHADER is enabled so as to allow a different texture wrap for the arcade artwork
/shaders/config.globals.inc - line 200: BG_IMAGE_WRAP_MODE is hardcoded to	1.0 (wrap to edge) because that's how it should be with this arcade artwork (ending with a black border)
/shaders/config.inc - line 107: STATIC_SUPPORT_BACKDROP hardcoded to 1.0 (this is why backdrops require a separate koko-aio-backdrops instance) 


# From here, the original text from the forked repository follows:

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
* [See here](docs.md)

***Additional artwork:***
* https://github.com/kokoko3k/koko-aio-slang-presets-and-overlays

***Actually, it provides emulation for:***
* Scanlines
* Screenlines
* RGB phosphors
* RGB deconvergence
* NTSC/PAL CVBS color bleeding
* NTSC color artifacting (early stage)
* Aperture grille and slot mask.
* Input signal glowing
* Output signal glowing
* Blooming
* Gamma, contrast, saturation, luminance, color temperature adjustments
* Black frame insertions through alternate blanking
* Interlace flickering, forcing and emulation
* Antialiasing
* Curvature
* Ambient lights
* Vignette and Spotlight
* Bezel (Thank you HyperspaceMadness for allowing me to rip his automagically generated bezel!)
  https://github.com/HyperspaceMadness/
* Background images
* Full screen glowing

***External code by:***
* Nvidia (FXAA)
* EasyMode (curvature related code)
        
# Examples

***monitor-slotmask-bloom-bezelwider - Arcade - Final fight***
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots/screenshots.3.5/monitor-slotmask-bloom-bezelwider.mame.ffight.png?raw=true)

***monitor-Commodore_1084S-wider - Amiga - ProjectX SE***
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots/screenshots.3.5/monitor-Commodore_1084S-wider.puae.projectx.png?raw=true)

***tv-PAL-my-old - Master System - Trans Bot***
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots/screenshots.3.5/tv-PAL-my-old,mastersystem.transbot.png?raw=true)

***tv-NTSC-1 - Genesis - Sonic 2***
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots/screenshots.3.5/tv-NTSC-1.md.sonic2.png?raw=true)

***tv-NTSC-2 - Snes - Aladdin***
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots/screenshots.3.5/tv-NTSC-2.snes.aladdin.png?raw=true)

***tv-aperturegrille-bloom-bezel - Amiga - Leander***
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots/screenshots.3.5/tv-aperturegrille-bloom-bezel.puae.leander.png?raw=true)
