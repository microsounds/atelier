#!/usr/bin/env sh

# xwin_decor.sh v1.0
# decorate root window

# fallback tiling background
bitmaps="$XDG_DATA_HOME/X11/bitmaps"
cpp -P <<- EOF | xargs xsetroot -bitmap "$bitmaps/diag.xbm"
	#include <colors/nightdrive.h>
	-bg COLOR15 -fg COLOR1
EOF

# custom background
# select N random images or video frames from any directory
# indicated by ~/.xdecor, one for each active display
zeropad() {
	[ $1 -gt 9 ] && echo $1 || echo "0$1"
}

rand() {
	{ od -N 4 -t u -A n | tr -d ' '; } < /dev/urandom
}

shuffle() {
	input="$(cat /dev/stdin)"
	lines=$(echo "$input" | wc -l)
	echo "$input" | tail -n +$((($(rand) % lines) + 1)) | head -n 1
}

ffmpeg_cat() {
	mediainfo "$1" --inform='Video;%FrameCount% %FrameRate%' \
		| while read -r f_count fps; do

		# calculate length and randomly select timestamp
		len=$(echo "scale=2; $f_count * (1 / $fps)" | bc)
		len=${len%.*}
		skip_len=150
		while :; do # reroll for random frame that skips over OPs/EDs
			sel=$(($(rand) % len))
			[ $len -le $skip_len ] && break # short video?
			[ $sel -gt $skip_len ] || continue
			[ $sel -lt $((len - skip_len)) ] || continue
			break
		done
		hrs=$((sel / 3600))
		min=$(((sel - (hrs * 3600)) / 60))
		sec=$((sel % 60))
		timest="$(zeropad $hrs):$(zeropad $min):$(zeropad $sec)"

		# saved for future use
		# ffmpeg -ss "$timest" -i "$1" -vframes 1 \
		#	-q:v 0 -f image2pipe -vcodec png - 2> /dev/null

		# low performance version
		ffmpegthumbnailer -i "$1" -s 0 -c png -t "$timest" -o -
	done
}

temp="$(mk-tempdir)" && mkdir -p "$temp"
trap 'rm -rf "$temp"' 0 1 2 3 6 15

config="$HOME/.xdecor"
[ -f "$config" ] || exit

# iterate through all active displays
xrandr -q | fgrep '*' | while read -r dpy; do
	# randomly select directory from ~/.xdecor
	{ sed -e 's/#.*//' -e '/^$/d' | shuffle; } < "$config" \
		| while read -r dir; do
		[ "${dir%${dir#?}}" = '~' ] && dir="$HOME/${dir#??}" # absolute path
		[ ! -z "$dir" ] || exit

		# randomly select file
		find "$dir" -type f \
			| egrep '\.(jpe?g|png|mkv|mp4|web(m|p))$' \
			| shuffle | while read -r sel; do
			[ ! -z "$sel" ] || exit

			case "$sel" in
				*mkv|*mp4|*webm) ffmpeg_cat "$sel";; # video file
				*) cat "$sel"
			esac
		done > "$temp/$(rand)"
	done
done

# pcmanfm desktop: set wallpaper by mangling config files and resetting
# use plain x window fallback via feh if pcmanfm not found
which pcmanfm > /dev/null && {
	find "$temp" -type f | nl -v 0 -n ln | while read -r mon file; do
		sed -E "s,^wallpaper=.*,wallpaper=$file,g" \
			-i ~/.config/pcmanfm/default/desktop-items-$mon.conf
	done
	pcmanfm --desktop-off && pcmanfm --desktop &
	sleep 1 # wait a while before cleaning up
} || find "$temp" -type f | xargs feh --no-fehbg --bg-fill
