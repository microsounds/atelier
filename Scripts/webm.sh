#!/usr/bin/env sh

## webm.sh v0.2
## Press Ctrl+C to end recording.

# quality
SIZE=3M
BITRATE=3M # 4M
SCALE=-1:-1 # 800:-1
FPS=60 # 25

# system
CORES=$(grep -c 'proc' /proc/cpuinfo)
RES=$(xdpyinfo | grep 'dim' | egrep -o '([0-9]+x?)+' | sed -n 1p)
TEMP=$(mktemp -u --suffix=".mp4")
FINAL="Screenshot - $(date '+%m%d%Y') - $(date '+%r').webm"

to_webm() {
	ffmpeg -i "$TEMP" -c:v libvpx -b:v $BITRATE -fs $SIZE -vf scale=$SCALE -threads $CORES -an "$FINAL"
	rm -v $TEMP
	echo "File created at: $(readlink -f "$FINAL")"
}

cat $0 | grep '^##' | sed 's/## //g'
trap to_webm 2
ffmpeg -loglevel panic -threads $CORES -framerate $FPS -video_size $RES -f x11grab -i :0.0+0,0 -vcodec libx264 -qp 0 -preset ultrafast "$TEMP"
