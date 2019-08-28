#!/usr/bin/env sh
## ~/.xinitrc

xrdb $HOME/.Xresources

# status line
while true; do
	_='・' # separator
	TEMP="$(acpi -tf | egrep -o '[0-9]+\.[0-9]')"
		[ -z "$TEMP" ] && TEMP="N/A" || TEMP="${TEMP}˚F"
	NET="$(nmcli | grep -w 'connected' | sed 's/connected to //g')"
		[ ! -z "$NET" ] || NET="disconnected"
	VOL=" $(amixer get 'Master' | egrep -o [[0-9]+%] | sed 1q | tr -d '[]')"
	BATT="$(acpi -b | cut -d ' ' -f 4-6 | sed 's/,$//g')"
	TIME="$(date '+%l:%M%P')"
	DAY="$(date '+%e')"
	case $DAY in
		1 | 21 | 31) DAY="${DAY}st";;
		2 | 22) DAY="${DAY}nd";;
		3 | 23) DAY="${DAY}rd";;
		*) DAY="${DAY}th"
	esac
	DATE="$(date "+%a, %b $DAY")"
	xsetroot -name "${TEMP} $_ ${NET} $_ ${BATT} $_ ${VOL} $_ ${DATE} $_ ${TIME}"
	sleep 10
done &

exec dwm

