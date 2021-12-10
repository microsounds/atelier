#!/usr/bin/env sh

# xwin_widgets.sh v0.4
# launch xload and xclock in a corner somewhere
# dwm ignores EMWH resize hints in tiling mode
# start in floating mode or override widgets to always float

# constants
LIST='xload xclock'
for f in $LIST; do COUNT=$((COUNT + 1)); done # calculate distance

# Xinerama support hacks
# xdotool windowmove commands cannot span across a multi-monitor Xinerama
# desktop. windowmove commands are bound to the dimensions of the monitor that
# window is currently on, this is considered the "active monitor". windowmove
# commands beyond those dimensions will silently fail. However, xdotool has no
# way of indicating the dimensions of the active monitor, which is required to
# generate correct x,y offsets for the spawned widgets.

# widgets will appear on the monitor that currently has the pointer, nudge
# pointer to the right to ensure pointer and widgets are on the same monitor
xdotool mousemove_relative --sync 1 0 click 1

# pointer location, provides MOUSE_XOFF, MOUSE_YOFF
eval "$(xdotool getmouselocation | sed -E 's/([a-z]+)/mouse_\1off/g' \
	| tr ':' '=' | tr 'a-z' 'A-Z' | tr ' ' '\n' | head -n 2)"

# detect display resolution by guessing which monitor has the pointer
# xrandr display dimension format: 'WIDTHxHEIGHT+x_off+y_off'
for f in $(xrandr -q | grep '[^dis]connected' \
	| egrep -o '([0-9]+x?\+?)+' | fgrep 'x'); do
	# dimensions
	dim="${f%%+*}"; WIDTH="${dim%x*}"; HEIGHT="${dim#*x}"
	# +x, +y offsets
	off="${f#$dim}"; x_off="${off%+*}"; y_off="${off#$x_off}"
	# strip leading symbols
	x_off="${x_off#?}"; y_off="${y_off#?}"
	# take a wild guess
	[ $MOUSE_XOFF -lt $((WIDTH + x_off)) ] && \
		[ $MOUSE_XOFF -gt $WIDTH ] && break
	[ $MOUSE_YOFF -lt $((HEIGHT + y_off)) ] && \
		[ $MOUSE_YOFF -gt $HEIGHT ] && break
done
SIZE=130      # window size
GAP=15        # gap between windows
EDGE=20       # distance from screen border

# dumb parser
# calculates starting positions
ARGS="${@:-vert bottom right}" # defaults
echo "$ARGS" | fgrep -q 'vert' && VERT=1 # vertical flag
for f in $(echo "$ARGS" | sed 's/-/ /g'); do
	case $f in # (display res - edge) - ((winsize + gap) * # of windows)
		left) XPOS=$EDGE;;
		upper|top) YPOS=$EDGE;;
		right) XPOS=$(( (WIDTH - EDGE) - ((SIZE + GAP) * ${VERT-$COUNT}) ));;
		bottom|lower) YPOS=$(( (HEIGHT - EDGE) - (SIZE + GAP) ));;
	esac
done

# launch from list
for prog in $LIST; do
	ps -e | fgrep -q "$prog" || $prog &
done

# positioning
for prog in $LIST; do
	# waste time while prog launches
	while ! window="$(xwininfo -name "$prog" 2> /dev/null)"; do :; done
	win_id=$(echo "$window" | egrep -o '0x[0-9a-f]+' | head -n 1)
	xdotool windowsize --sync $win_id $SIZE $SIZE &
	xdotool windowmove --sync $win_id $XPOS $YPOS &
	jump=$((SIZE + GAP)) # determine placement
	if [ ! -z $VERT ]; then
		[ $((YPOS - jump)) -lt 0 ] && jump=$((jump * -1))
		YPOS=$((YPOS - jump))
	else
		XPOS=$((XPOS + jump))
	fi
done
