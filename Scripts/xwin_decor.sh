#!/usr/bin/env sh

# runs startup items that aren't daemons
# set as callback script that executes upon display resolution change

images="$HOME/Pictures/active"
cpp << EOF | egrep -o '#[A-Z0-9]+' | while read color; do
	#include <colors/nightdrive.h>
	BGCOLOR
EOF
	xsetroot -solid "$color"
done
feh --no-fehbg --bg-fill "$(find "$images" -type f | shuf | head -1)" &
~/Scripts/xload.sh vert bottom-right &
