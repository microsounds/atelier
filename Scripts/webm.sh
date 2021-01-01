#!/usr/bin/env sh

## webm.sh v0.5
#  screen recorder, outputs soundless webm for certain anime imageboards
## Press Ctrl+C to end recording, press Ctrl+C again to cancel.

# colors
INFO=37
OK=32
ERR=31

# quality
SIZE=2.8M
CONSTQ=31
BITRATE=3M # 4M
SCALE=-1:-1 # 800:-1
FPS=60 # 25

# system
NAME="${0##*/}" # derive script name
CORES="$(grep -c '^proc' /proc/cpuinfo)"
RES="$(xdpyinfo | grep 'dim' | egrep -o '([0-9]+x?)+' | head -n 1)"
FINAL="$(date '+%Y-%m-%d-%H%M%S')_${RES}_${NAME%.*}.webm"
KEY="$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=10 count=1 2> /dev/null)"
TEMP="/tmp/${KEY}.mp4"

info() { echo "\e[1;${1}m${2}\e[0m"; }

to_webm() {
	iter=$((iter + 1))
	if [ $iter -lt 2 ]; then
		for f in $(seq 2); do
			info $INFO "Pass $f encoding..."
			case $f in
				1) OUTPUT='-f null /dev/null';;
				2) OUTPUT="$PWD/$FINAL";;
			esac
			ffmpeg -hide_banner -loglevel info -i "$TEMP" -c:v libvpx \
				-b:v $BITRATE -crf $CONSTQ -fs $SIZE -vf scale=$SCALE \
				-fs $SIZE -threads $CORES -an -passlogfile $KEY -pass $f $OUTPUT
		done
		rm -v "$TEMP" "$PWD/$KEY"*
		info $OK "File saved at: $PWD/$FINAL"
	else
		info $ERR "Terminated abruptly..."
		rm -v "$TEMP" "$PWD/$KEY"* "$FINAL" && exit 1
	fi
}

info $INFO "$(cat $0 | grep '^##' | sed 's/## //g')"
iter=0; trap to_webm 2
ffmpeg -loglevel panic -threads $CORES -framerate $FPS -video_size $RES \
       -f x11grab -i :0.0+0,0 -vcodec libx264 -qp 0 -preset ultrafast "$TEMP"
