#!/usr/bin/env sh
# decorate root window

# fallback tiling background
bitmaps="$XDG_DATA_HOME/X11/bitmaps"
cpp -P <<- EOF | xargs xsetroot -bitmap "$bitmaps/diag.xbm"
	#include <colors/nightdrive.h>
	-bg COLOR15 -fg COLOR1
EOF

# custom wallpaper
# select random image or video frame from a directory indicated by ~/.xdecor
rand() { od -N 4 -t u -A n < /dev/urandom; }
setwall='feh --no-fehbg --bg-fill -g +0+0 -'
config="$HOME/.xdecor"

[ -f "$config" ] || exit
lines=$(wc -l) < "$config"

# select random directory
{ grep . | tail -n $((($(rand) % lines) + 1)) | head -n 1; } < "$config" \
	| while read -r dir; do
	[ "${dir%${dir#?}}" = '~' ] && dir="$HOME/${dir#??}" # absolute path
	[ ! -z "$dir" ] || exit
	sel="$(find "$dir" -type f | \
		egrep '\.(jpe?g|png|mkv|mp4|web(m|p))$' | shuf -n 1)"
	[ ! -z "$sel" ] || exit
	case "$sel" in
		*jpg|*jpeg|*png|*webp) $setwall < "$sel";;
		*)
			while seed=$(($(rand) % 100)); do # exclude OP/EDs
				[ $seed -lt 15 ] || [ $seed -gt 85 ] || break
			done
			ffmpegthumbnailer -i "$sel" -s 0 -c png -t $seed -o - | $setwall
	esac
done



