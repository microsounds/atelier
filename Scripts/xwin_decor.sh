#!/usr/bin/env sh

# decorate root window
# use bitmap background as fallback

images="$HOME/Pictures/active"
bitmaps='/usr/include/X11/bitmaps'

cpp << EOF | egrep -v '^(#|$)' | while read color; do
	#include <colors/overcast.h>
	-bg str(COLOR0) -fg str(COLOR9)
EOF
	echo "$color" | xargs -o xsetroot -bitmap "$bitmaps/gray3"
done

find "$images" -type f | shuf | head -1 | xargs feh --no-fehbg --bg-fill &
~/Scripts/xload.sh vert bottom-right &
