#!/usr/bin/env sh
# decorate root window

# fallback tiling background
bitmaps="$HOME/.local/share/X11/bitmaps"
cpp <<- EOF | egrep -v '^(#|$)' | while read -r color; do
	#include <colors/nightdrive.h>
	-bg str(COLOR15) -fg str(COLOR1)
EOF
	echo "$color" | xargs -o xsetroot -bitmap "$bitmaps/diag.xbm"
done

# select random wallpaper
images="$HOME/Pictures/active"
sel="$(find "$images" -type f | shuf | head -n 1)"
feh --no-fehbg --bg-fill -g '+0+0' "$sel" || exit
