#!/usr/bin/env sh

# xrandr_cycle.sh v0.3
# re-entrantly cycle between connected displays

announce() { echo "$@"; "$@"; }

# option flags
for f in "$@"; do case "$f" in
	-d) # apply custom display layout from ~/.xrandr
		[ -f ~/.xrandr ] && sed -e 's/#.*//' -e '/^$/d' < ~/.xrandr \
			| while read -r line; do
			announce xrandr $line
		done
		exit;;
esac; done

IFS='
'
# list connected displays
# append control chars and special device ALL for convenience
unset dpys
for f in $(xrandr -q | egrep '(\*|[^dis]connected)') ALL; do
	case "${f%${f#?}}" in
		' ') dpys="${dpys%?}* ";; # mark active display*
		*) dpys="$dpys${f%% *} "
	esac
done

# if all displays (minus ALL) are active, restart the cycle
num=$(echo "$dpys" | wc -w)
if [ $((num - 1)) -eq \
	$(echo "$dpys" | tr ' ' '\n' | fgrep -c '*') ]; then
	dpys="$(echo "$dpys" | sed -e 's/*//g' -e 's/ALL/&*/')"
fi
echo "Displays available: $dpys"

# cycle through next inactive monitor
unset IFS
idx=1; for f in $dpys; do
	case "$f" in
		*\*) break;;
		*) idx=$((idx + 1))
	esac
done
sel="$(echo "$dpys" | tr ' ' '\n' \
	| tail -n +$(((idx % num) + 1)) | head -n 1)"

# strip control chars and special device ALL
dpys="$(echo "$dpys" | sed -e 's/*//' -e 's/ALL//')"
echo "Selecting: $sel"

# generate xrandr command to satisfy request
unset cmd
if [ "$sel" = 'ALL' ]; then
	[ -f "$HOME/.xrandr" ] && exec $0 -d

	# if ~/.xrandr doesn't exist
	# enable all displays with fallback command
	# fallback command may mirror all displays by default
	for f in $dpys; do
		cmd="$cmd --output $f --auto"
	done
else
	cmd="$cmd --output $sel --auto"
	for f in $(echo "$dpys" | sed -e "s/$sel//"); do
		cmd="$cmd --output $f --off"
	done
fi

announce xrandr $cmd
