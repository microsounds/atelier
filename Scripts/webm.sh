#!/usr/bin/env sh

## webm.sh v0.3
## Press Ctrl+C to end recording, press Ctrl+C again to cancel.

# colors
INFO=37
OK=32
ERR=31

# quality
SIZE=3M
BITRATE=3M # 4M
SCALE=-1:-1 # 800:-1
FPS=60 # 25

# system
CORES=$(grep -c '^proc' /proc/cpuinfo)
RES=$(xdpyinfo | grep 'dim' | egrep -o '([0-9]+x?)+' | sed -n 1p)
FINAL="$(date '+Screenshot - %m%d%Y - %r').webm"
TEMP="/tmp/$(cat /dev/urandom | tr -cd 'a-z0-9' | head -c 10).mp4"

info() { echo "\e[1;${1}m${2}\e[0m"; }

to_webm() {
	trap really_quit 2
	info $INFO "Encoding..."
	ffmpeg -hide_banner -i "$TEMP" \
	       -c:v libvpx -b:v $BITRATE -fs $SIZE -vf scale=$SCALE -threads $CORES -an "$FINAL"
	rm -v "$TEMP"
	info $OK "File saved at: $PWD/$FINAL"
}

really_quit() {
	info $ERR "Terminated abruptly..."
	rm -v "$TEMP" "$FINAL"
	exit 1
}

info $INFO "$(cat $0 | grep '^##' | sed 's/## //g')"
trap to_webm 2
ffmpeg -loglevel panic -threads $CORES -framerate $FPS -video_size $RES \
       -f x11grab -i :0.0+0,0 -vcodec libx264 -qp 0 -preset ultrafast "$TEMP"
