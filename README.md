    Koko-aio shader is meant to be an all-in one crt shader.
    It can be configured with many parameters, so that can be
    scaled to run on even on modest gpus while still developed to
    run with heavier presets on at least Haswell+ iGpus.
    It is not meant to simulate the internal behaviour of CRT displays,
    but to give users the parameters to make their monitors to look similar.
    Several presets are included.

    Actually it provides emulation for:
        scanlines, screenlines, RGB vertical masks, horizontal slot masks,
        glowing, haloing, blooming, gamma and saturation correction,
        black frame insertions, interlace emulation, antialiasing.

    External code by:
        CRT - Guest - Dr.Venom (single pass bloom function)
        Nvidia (FXAA)

*** Aperture grille, no scanlines emulation: ***
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots.2022-29-07/crt-tv-aperturegrille.png?raw=true)

Slot mask, RGB phosphors, no scanline emulation:
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots.2022-29-07/crt-tv-slotmask.png?raw=true)

Slot mask, RGB phosphors, with scanlines emulation and bloom:
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots.2022-29-07/crt-monitor-slotmask-bloom.png?raw=true)

Scanlines and simple RGB phosphors with bloom:
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots.2022-29-07/crt-monitor-bloom.png?raw=true)

Just Scanlines:
![alt text](https://github.com/kokoko3k/koko-aio-slang/blob/main/screenshots.2022-29-07/crt-monitor-scanlines-clean.png?raw=true)
[/b]
