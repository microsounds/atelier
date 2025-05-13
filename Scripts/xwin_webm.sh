#!/usr/bin/env sh

## xwin_webm.sh v0.6
## Press Ctrl+C to stop recording, press Ctrl+C again to cancel.

# simple screen recorder, edit settings to suit
# outputs soundless vp8 webm as required by certain anime imageboards

# colors
INFO=37
OK=32
ERR=31

# quality settings
SIZE=2.8M
CONSTQ=31
BITRATE=3M # 4M
SCALE=-1:-1 # 800:-1
FPS=25 # 25

# system
NAME="${0##*/}" # derive script name
KEY="$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=10 count=1 2> /dev/null)"
CORES="$(grep -c '^proc' /proc/cpuinfo)"

info() { echo "\e[1;${1}m${2}\e[0m"; }

# x,y,w,h display constants
# capture entire display by default
OFFSET='0,0' # x,y
RES="$(xdpyinfo | grep 'dim' | egrep -o '([0-9]+x?)+' | head -n 1)" # WxH

# interactively select subset of display
if [ "$1" = '-s' ]; then
	shift 1
	info $INFO 'Select part of the display to record...'
	RES="$(slop -b 1)" 2> /dev/null || exit 1
	OFFSET="$(printf '%s' "$RES" | tr '+' '\n' | tail -n 2 | tr '\n' ',')"
	RES="$(echo "$RES" | tr '+' '\n' | head -n 1)"
fi

# filenames
TEMP="$PWD/${KEY}.mp4"
FINAL="$PWD/$(date '+%Y-%m-%d-%H%M%S')_${RES}_${NAME%.*}.webm"

to_webm() {
	iter=$((iter + 1))
	if [ $iter -lt 2 ]; then
		# rewrite ffmpeg command to use 2-pass encoding
		twopass ffmpeg -loglevel panic -i "$TEMP" -c:v libvpx-vp9 \
			-b:v $BITRATE -crf $CONSTQ -fs $SIZE -vf scale=$SCALE \
			-fs $SIZE -threads $CORES -an "$FINAL"
		rm -fv "$PWD/$KEY"*
		info $OK "File saved at: $FINAL"
	else
		info $ERR "Terminated abruptly..."
		rm -fv "$PWD/$KEY"* "$FINAL" && exit 1
	fi
}

info $INFO "$(cat $0 | grep '^##' | sed 's/## //g')"
iter=0; trap to_webm 2
ffmpeg -loglevel panic -threads $CORES -framerate $FPS -video_size $RES \
	-f x11grab -i :0.0+$OFFSET -c:v libx264 -qp 0 -preset ultrafast "$TEMP"
