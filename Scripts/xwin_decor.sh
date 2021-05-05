#!/usr/bin/env sh
# decorate root window

# fallback tiling background
bitmaps="$XDG_DATA_HOME/X11/bitmaps"
cpp -P <<- EOF | xargs xsetroot -bitmap "$bitmaps/diag.xbm"
	#include <colors/nightdrive.h>
	-bg COLOR15 -fg COLOR1
EOF

# select N random images or video frames from any directory
# indicated by ~/.xdecor, one for each active display
rand() {
	{ od -N 4 -t u -A n | tr -d ' '; } < /dev/urandom
}

temp="$(mk-tempdir)" && mkdir -p "$temp"
trap 'rm -rf "$temp"' 0 1 2 3 6

config="$HOME/.xdecor"
[ -f "$config" ] || exit
lines=$(wc -l) < "$config"

# iterate through all active displays
xrandr -q | fgrep '*' | while read -r dpy; do
	# randomly select directory
	{ grep . | tail -n $((($(rand) % lines) + 1)) | head -n 1; } < "$config" \
		| while read -r dir; do
		[ "${dir%${dir#?}}" = '~' ] && dir="$HOME/${dir#??}" # absolute path
		[ ! -z "$dir" ] || exit

		# randomly select file
		find "$dir" -type f \
			| egrep '\.(jpe?g|png|mkv|mp4|web(m|p))$' | shuf -n 1 \
			| while read -r sel; do
			[ ! -z "$sel" ] || exit

			case "$sel" in
				*mkv|*mp4|*webm) # video file
					while seed=$(($(rand) % 100)); do # exclude OP/EDs
						[ $seed -lt 15 ] || [ $seed -gt 85 ] || break
					done
					ffmpegthumbnailer -i "$sel" -s 0 -c png -t $seed -o - ;;
				*) cat "$sel"
			esac
		done
	done > "$temp/$(rand)"
done

find "$temp" -type f | xargs feh --no-fehbg --bg-fill -g +0+0
