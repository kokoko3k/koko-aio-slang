# Koko-aio

Koko-aio shader is meant to be an all-in one crt shader.<br>
It can be configured with many parameters, so that can be
scaled to run on even on modest gpus while still developed to
run with heavier presets on at least Haswell+ iGpus.<br>
While it is not meant to simulate the internal behaviour of CRT displays,<br>
it aims to give users "visual" parameters to make their monitors look similar.<br>
Several presets are included.<br>

***Actually, it provides emulation for:***
* Scanlines
* Screenlines
* RGB phosphors
* Aperture grille and slot mask.
* Input signal glowing
* Output signal glowing
* Blooming
* Gamma and saturation correction,
* Black frame insertions through alternate blanking
* Interlace forcing and emulation
* Antialiasing
* Curvature
* Ambient lights
* Vignette and Spotlight
* Bezel (Thank you HyperspaceMadness for allowing me to rip his automagically generated bezel!)
  https://github.com/HyperspaceMadness/

***External code by:***
* CRT - Guest - Dr.Venom (single pass bloom function)
* Nvidia (FXAA)
* EasyMode (curvature related code)
        
# Examples

![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/Screenshots_2.0/ffight.png?raw=true)

![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/Screenshots_2.0/jim.png?raw=true)

![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/Screenshots_2.0/mvc.png?raw=true)

![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/Screenshots_2.0/sonic.png?raw=true)

![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/Screenshots_2.0/spft.png?raw=true)


