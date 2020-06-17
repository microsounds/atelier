#!/usr/bin/env sh

# decorate root window
# use bitmap background as fallback

position='--bg-fill -g +0+0' # top of wallpaper
images="$HOME/Pictures/active"
bitmaps="$HOME/.local/share/X11/bitmaps"

# xload
~/Scripts/xload.sh vert bottom-right &

# fallback wallpaper
cpp << EOF | egrep -v '^(#|$)' | while read -r color; do
	#include <colors/nightdrive.h>
	-bg str(COLOR15) -fg str(COLOR1)
EOF
	echo "$color" | xargs -o xsetroot -bitmap "$bitmaps/diag.xbm"
done

# wallpaper
find "$images" -type f | shuf | head -1 | xargs feh --no-fehbg $position || exit
