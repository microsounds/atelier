#!/usr/bin/env sh
# launch xload and xclock in top-right corner

LIST="xload xclock"
COUNT=$(echo "$LIST" | wc -w)
SCREEN=$(xdpyinfo | grep 'dim' | grep -Eo '([0-9]+x?)+' | sed -n '1p')
WIDTH=${SCREEN%x*} HEIGHT=${SCREEN#*x}
SIZE=130  # window size
GAP=15    # gap between windows
EDGE=25   # distance from screen border
XPOS=$(((WIDTH - EDGE) - ((SIZE + GAP) * COUNT)))
YPOS=$EDGE

for PROG in $LIST; do
	if ! ps -xc | grep "$PROG" > /dev/null; then
		$PROG &
		while ! wmctrl -l | grep "$PROG" > /dev/null; do
			: # keep spinning
		done
	fi
	WINDOW=$(wmctrl -l | grep "$PROG" | sed -n 's/ .*//p')
	wmctrl -i -r "$WINDOW" -b add,skip_taskbar,skip_pager
	wmctrl -i -r "$WINDOW" -b add,sticky,bottom
	wmctrl -i -r "$WINDOW" -e 0,$XPOS,$YPOS,$SIZE,$SIZE
	XPOS=$((XPOS + (SIZE + GAP)))
done
