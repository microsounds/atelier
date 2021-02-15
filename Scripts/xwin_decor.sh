#!/usr/bin/env sh
# decorate root window

# fallback tiling background
bitmaps="$HOME/.local/share/X11/bitmaps"
cpp <<- EOF | egrep -v '^(#|$)' | xargs xsetroot -bitmap "$bitmaps/diag.xbm"
	#include <colors/nightdrive.h>
	-bg COLOR15 -fg COLOR1
EOF

# custom wallpaper
# select random image or video frame from directory indicated by ~/.xdecor
config="$HOME/.xdecor"
setwall='feh --no-fehbg --bg-fill -g +0+0 -'
[ ! -f "$config" ] && exit || read -r dir < "$config"
[ "${dir%${dir#?}}" = '~' ] && dir="$HOME/${dir#??}" # absolute path

[ ! -z "$dir" ] || exit
sel="$(find "$dir" -type f | egrep '\.(jpe?g|png|mkv|mp4)$' | shuf -n 1)"
[ ! -z "$sel" ] || exit
case "$sel" in
	*jpg|*jpeg|*png) $setwall < "$sel";;
	*)
		mediainfo "$sel" --output='Video;%FrameCount% %FrameRate%' \
			| while read -r f_count fps; do
			v_length="$(echo "scale=2; $f_count * (1 / $fps)" | bc)"
			seed="$(od -N 4 -t u -A n < /dev/urandom | tr -d ' ')"
			ffmpeg -ss "$((seed % ${v_length%.*}))" -i "$sel" -vframes 1 \
				-q:v 0 -f image2pipe -vcodec png - 2> /dev/null | $setwall
		done;;
esac
