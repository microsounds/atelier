#!/usr/bin/env sh

# xwin_decor.sh v1.4
# attempt to decorate X root window several ways

config="$HOME/.xdecor"
bitmaps="$XDG_DATA_HOME/X11/bitmaps"
pcmanfm_config="$XDG_CONFIG_HOME/pcmanfm/default"

# purest form of fallback
# decorate bare X root window with classic tiling bitmap
cpp -P <<- EOF | xargs xsetroot -bitmap "$bitmaps/diag.xbm"
		#include <colors/nightdrive.h>
		-fg COLOR1 -bg COLOR15
EOF

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

		# hard cap on execution time to prevent thermal runaway
		while [ "$(ps -p "$$" -o 'etimes=')" -lt 5 ]; do

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
temp="$XDG_RUNTIME_DIR/${0##*/}.$$" && mkdir -p "$temp"

# pcmanfm will randomly re-read wallpaper files after they're deleted, leading
# to black screens, just leave temp dir trash to be cleaned up on next run
# trap 'rm -rf "$temp"' 0 1 2 3 6 15

# custom background generator
# select N random images or video frames from any directory
# listed in ~/.xdecor, one for each active monitor

# iterate through all active displays
xrandr -q | fgrep '*' | while read -r dpy; do

	# second purest form of fallback
	# generate tiling bitmap as a portable PNG
	if [ ! -f "$config" ]; then
		cpp -P <<- EOF | xargs convert "$bitmaps/diag.xbm" \
			> "$temp/$(rand).png" && continue
			#include <colors/nightdrive.h>
			-fill COLOR1 -opaque black
			-fill COLOR15 -opaque white
			png:-
		EOF
	fi

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

# multi-monitor mode, adds 50% more jank
# pcmanfm doesn't support setting multiple wallpapers via cli
# set wallpaper by mangling config and force restarting pcmanfm
unset MULTI
[ "$(find "$temp" -type f | wc -l)" -gt 1 ] && MULTI=1
pcmanfm_mangle() {
	case "$1" in
		1) sed -E \
			-e "s,^wallpaper=.*,wallpaper=$2,g" \
			-e "s,^wallpaper_mode=.*,wallpaper_mode=$3,g" \
			-i "$pcmanfm_config/desktop-items-$4.conf";;
		*) pcmanfm -w "$2" --wallpaper-mode="$3"
	esac
}
is_small() {
	return "$(convert "$1" -format "%[fx:(w<600 || h<600)?0:1]" info:)"
}

# set pcmanfm --desktop wallpaper
# decorate bare X root window via feh if pcmanfm not found
which pcmanfm > /dev/null && {
	find "$temp" -type f | nl -v 0 -n ln | while read -r mon file; do
		! is_small "$file" && wp_mode='crop' || wp_mode='tile'
		pcmanfm_mangle "$MULTI" "$file" "$wp_mode" "$mon"
	done
	[ ! -z "$MULTI" ] && pcmanfm --desktop-off && pcmanfm --desktop &

	# waifu2x: upscale and denoise images on machines with dGPUs, extremely slow
	# do NOT attempt on integrated gfx
	if nvidia-smi > /dev/null 2>&1 || rocm-smi > /dev/null 2>&1; then
		find "$temp" -type f | nl -v 0 -n ln | while read -r mon file; do
			{	printf '%s' '[waifu2x]: '
				waifu2x-ncnn-vulkan -i "$file" -o "$file.tmp.png" \
			       -f png -s 2 -n 3 -m $XDG_DATA_HOME/waifu2x/models-cunet 2>&1
			    mv "$file.tmp.png" "$file"
			} | notify-send -t 0.5
			! is_small "$file" && wp_mode='crop' || wp_mode='tile'
			pcmanfm_mangle "$MULTI" "$file" "$wp_mode" "$mon"
		done
		[ ! -z "$MULTI" ] && pcmanfm --desktop-off && pcmanfm --desktop &
	fi
} || find "$temp" -type f | {
	input="$(cat /dev/stdin)"
	# enable tiling if if image is extremely small
	for f in $input; do
		! is_small "$f" && wp_mode='fill' || wp_mode='tile'
	done
	echo "$input" | xargs feh --no-fehbg --bg-$wp_mode
}
