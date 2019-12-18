#!/usr/bin/env sh
# launch xload and xclock in a corner somewhere
# dwm ignores EWMH resizing by default and requires float overrides

# constants
LIST="xload xclock"
COUNT=$(echo "$LIST" | wc -w)
SCREEN=$(xdpyinfo | grep 'dim' | egrep -o '([0-9]+x?)+' | sed -n 1p)
SIZE=130  # window size
GAP=15    # gap between windows
EDGE=20   # distance from screen border

# dumb parser
# calculates starting positions
ARGS="${@:-bottom right}" # defaults
[ $(echo "$ARGS" | grep -c 'vert') -gt 0 ] && VERT=1 # vertical flag
for f in $(echo "$ARGS" | sed 's/-/ /g'); do
	case $f in # (display res - edge) - ((winsize + gap) * # of windows)
		left)           XPOS=$EDGE;;
		upper | top)    YPOS=$EDGE;;
		right)          XPOS=$(( (${SCREEN%x*} - EDGE) - ((SIZE + GAP) * ${VERT-$COUNT}) ));;
		bottom | lower) YPOS=$(( (${SCREEN#*x} - EDGE) - (SIZE + GAP) ));;
	esac
done

# launch from list
for prog in $LIST; do
	if ! ps -xc | grep "$prog" > /dev/null; then
		$prog &
		while ! wmctrl -l | grep "$prog" > /dev/null; do
			: # keep spinning
		done
	fi
	win_id=$(wmctrl -l | grep "$prog" | egrep -o '0x[0-9a-f]+')
	wmctrl -i -r "$win_id" -b add,skip_taskbar,skip_pager
	wmctrl -i -r "$win_id" -b add,sticky,bottom
	wmctrl -i -r "$win_id" -e 0,$XPOS,$YPOS,$SIZE,$SIZE
	jump=$((SIZE + GAP)) # determine placement
	if [ ! -z $VERT ]; then
		[ $((YPOS - jump)) -lt 0 ] && jump=$((jump * -1))
		YPOS=$((YPOS - jump))
	else
		XPOS=$((XPOS + jump))
	fi
done
