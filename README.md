# Koko-aio

Koko-aio shader is meant to be an all-in one crt shader.<br>
It can be configured with many parameters, so that can be
scaled to run on even on modest gpus while still developed to
run with heavier presets on at least Haswell+ iGpus.<br>
While it is not meant to simulate the internal behaviour of CRT displays,<br>
it aims to give users "visual" parameters to make their monitors to look similar.<br>
Several presets are included.<br>

***Actually it provides emulation for:***
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
* Curvature (thanks EasyMode)

***External code by:***
* CRT - Guest - Dr.Venom (single pass bloom function)
* Nvidia (FXAA)
* EasyMode (curvature related code)
        
# Examples

**Aperture grille, no scanlines emulation:**
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots.2022-29-07/crt-tv-aperturegrille.png?raw=true)

**Slot mask, RGB phosphors, no scanline emulation:**
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots.2022-29-07/crt-tv-slotmask.png?raw=true)

**Slot mask, RGB phosphors, with scanlines emulation and bloom:**
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots.2022-29-07/crt-monitor-slotmask-bloom.png?raw=true)

**Scanlines and simple RGB phosphors with bloom:**
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots.2022-29-07/crt-monitor-bloom.png?raw=true)

**Just Scanlines:**
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots.2022-29-07/crt-monitor-scanlines-clean.png?raw=true)

