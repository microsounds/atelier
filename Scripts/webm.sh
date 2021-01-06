#!/usr/bin/env sh

## webm.sh v0.5
## Press Ctrl+C to stop recording, press Ctrl+C again to cancel.

# simple screen recorder
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
FPS=60 # 25

# system
KEY="$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=10 count=1 2> /dev/null)"
RES="$(xdpyinfo | grep 'dim' | egrep -o '([0-9]+x?)+' | head -n 1)"
NAME="${0##*/}" # derive script name
CORES="$(grep -c '^proc' /proc/cpuinfo)"

# filenames
TEMP="$PWD/${KEY}.mp4"
FINAL="$PWD/$(date '+%Y-%m-%d-%H%M%S')_${RES}_${NAME%.*}.webm"

info() { echo "\e[1;${1}m${2}\e[0m"; }

# rewrite ffmpeg command to use 2-pass encoding
twopass() {
	final_opt="$(eval "echo \$$(($#))")"
	for f in "$@"; do
		shift
		[ "$f" = "$final_opt" ] && continue
		set -- "$@" "$f"
	done
	for f in $(seq 2); do
		info $INFO "Pass $f encoding..."
		case $f in
			1) "$@" -passlogfile $KEY -pass $f -f null /dev/null;;
			2) "$@" -passlogfile $KEY -pass $f "$final_opt";;
		esac
	done
}

to_webm() {
	iter=$((iter + 1))
	if [ $iter -lt 2 ]; then
		twopass ffmpeg -hide_banner -loglevel info -i "$TEMP" -c:v libvpx \
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
	-f x11grab -i :0.0+0,0 -c:v libx264 -qp 0 -preset ultrafast "$TEMP"
