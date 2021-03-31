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
sel="$(find "$dir" -type f | \
	egrep '\.(jpe?g|png|mkv|mp4|web(m|p))$' | shuf -n 1)"
[ ! -z "$sel" ] || exit
case "$sel" in
	*jpg|*jpeg|*png|*webp) $setwall < "$sel";;
	*)
		while seed="$(od -N 4 -t u -A n < /dev/urandom)"; do
			seed=$((seed % 100))
			[ $seed -lt 15 ] || [ $seed -gt 85 ] || break
		done
		ffmpegthumbnailer -i "$sel" -s 0 -c png -t $seed -o - | $setwall
esac
