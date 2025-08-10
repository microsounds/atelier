#!/usr/bin/env sh

# xwin_decor.sh v1.1
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

		# calculate length of input file
		len=$(echo "scale=2; $f_count * (1 / $fps)" | bc)
		len=${len%.*}
		while :; do
			# keep rerolling for random frames that skip over OP/EDs
			skip_len=150
			sel=$(($(rand) % len))
			[ $len -le $skip_len ] # short video?
			[ $sel -gt $skip_len ] || continue
			[ $sel -lt $((len - skip_len)) ] || continue

			# convert to timestamp
			hrs=$((sel / 3600))
			min=$(((sel - (hrs * 3600)) / 60))
			sec=$((sel % 60))
			timest="$(zeropad $hrs):$(zeropad $min):$(zeropad $sec)"

			# extract and cat frame
			# keep rerolling if frame chosen is dark, all black/white or not
			# interesting, boring frames usually have a standard deviation of
			# 0.16 or less
			frame="$temp/$(rand)"
			ffmpegthumbnailer -i "$1" -s 0 -c png -t "$timest" -o "$frame"
			std_dev="$(convert "$frame" -colorspace Gray -format "%[fx:standard_deviation]" info:)"
			std_dev="$(echo "$std_dev * 100" | bc | sed 's/\..*$//')"
			if [ $std_dev -lt 17 ]; then
				rm -f "$frame" && continue
			else
				cat "$frame" && rm -f "$frame" && break
			fi
		done

		# saved for future use
		# ffmpeg -ss "$timest" -i "$1" -vframes 1 \
		#	-q:v 0 -f image2pipe -vcodec png - 2> /dev/null
	done
}

# remove trash from previous iterations
rm -rf "$XDG_RUNTIME_DIR/${0##*/}"*
temp="$XDG_RUNTIME_DIR/${0##*/}-$$" && mkdir -p "$temp"

# pcmanfm will randomly re-read wallpaper files after they're deleted, leading
# to black screens, just leave temp dir trash to be cleaned up on next run
# trap 'rm -rf "$temp"' 0 1 2 3 6 15

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
		notify-send -t 0.5 "[${0##*/}]: Selecting from ${sel##*/}" &
		done > "$temp/$(rand).png"
	done
done

# pcmanfm --desktop: set wallpaper by mangling config files and resetting
# use plain x window fallback via feh if pcmanfm not found
which pcmanfm > /dev/null && {
	find "$temp" -type f | nl -v 0 -n ln | while read -r mon file; do
		sed -E "s,^wallpaper=.*,wallpaper=$file,g" \
			-i ~/.config/pcmanfm/default/desktop-items-$mon.conf
	done && pcmanfm --desktop-off && pcmanfm --desktop &

	# waifu2x: upscale and denoise images on desktop, extremely slow
	find "$temp" -type f | while read -r file; do
		is-chromebook && exit 0
		{	printf '%s' "[waifu2x]: "
			waifu2x-ncnn-vulkan -i "$file" -o "$file.tmp.png" \
		       -f png -s 2 -n 3 -m $XDG_DATA_HOME/waifu2x/models-cunet 2>&1
		    mv "$file.tmp.png" "$file"
		} | notify-send -t 0.5
	done && pcmanfm --desktop-off && pcmanfm --desktop &
} || find "$temp" -type f | xargs feh --no-fehbg --bg-fill
