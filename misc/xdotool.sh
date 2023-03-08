#bulk save presets and rename them.
#set retroarch input to X11 or it will not work.

function SendString {
    STRING=$1
    echo $STRING:
    for (( i=0; i<${#STRING}; i++ )); do
      k=${STRING:$i:1}
      echo "--"$k
      xdotool keydown "$k"
      sleep 0.1
      xdotool keyup "$k"
      sleep 0.1
      echo $k
    done
	sleep 1
}

function SendKey {
	echo "--"$1
    xdotool keydown "$1"
    sleep 0.1
    xdotool keyup "$1"
    sleep 1
}


function xdosavepreset {
	sleep $1
	xdotool search --class RetroArch windowactivate
	sleep 1
	SendKey F1
	SendKey s
	SendString sh
	SendKey "Return"
	SendKey "Return"

	SendKey s
	SendString sa
	SendKey "Return"
	SendKey "Return"


	SendKey s
	SendString sa
	SendKey "Return"
	SendKey "Return"

	SendKey 1
	SendKey "Return"
	SendKey "Escape"
	SendKey "Escape"
	SendKey "Escape"
	SendKey "Escape"
}

for preset in $(ls -1 /koko/koko-aio-slang/presets/* | grep slangp) ; do 
	echo $preset
	presetname=$(basename "$preset")
	echo $presetname
	xdosavepreset 5 &
	retroarch  -L /koko/.config/retroarch/cores/mame2003_plus_libretro.so romname.zip \
	--set-shader $preset  2>&1|grep -i error 
	mv /koko/.config/retroarch/shaders/1.slangp /koko/.config/retroarch/shaders/$presetname
done



exit

	f1
	s
	sh
	invio
	invio

	s
	sa
	invio
	invio

s
sa
invio
invio

1
esc
esc
