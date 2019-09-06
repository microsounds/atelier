#!/usr/bin/env sh

# dwm status bar
# returns system information

while true; do
	_='・' # separator
	FAN_DATA='/proc/acpi/ibm/fan'
	TEMP="$(acpi -tf | egrep -o '[0-9]+\.[0-9]+')˚F"
	if [ ! -f $FAN_DATA ]; then FAN="$TEMP"; # not a thinkpad
	else
		FAN="$((($(cat $FAN_DATA | egrep -o '[0-9]+') * 100) / 5300))"
		[ ! "$FAN" -eq 0 ] && FAN="Fan ${FAN}%" || FAN="$TEMP"
	fi
	NET="$(nmcli | grep -w 'connected' | sed 's/connected to //g')"
	[ ! -z "$NET" ] || NET="No Network"
	VOL="Vol $(amixer get 'Master' | egrep -o [[0-9]+%] | sed 1q | tr -d '[]')"
	amixer get 'Master' | grep 'off' && VOL="${VOL}, muted"
	BAT="Bat $(acpi -b | egrep -o '[0-9]+\%.*')"
	TIME="$(date '+%l:%M%P' | sed 's/^ //g')"
	DAY="$(date '+%e' | sed 's/^ //g')"
	case $DAY in
		1 | 21 | 31) DAY="${DAY}st";;
		2 | 22) DAY="${DAY}nd";;
		3 | 23) DAY="${DAY}rd";;
		*) DAY="${DAY}th"
	esac
	DATE="$(date "+%a, %b $DAY")"
	xsetroot -name " ${FAN} $_ ${NET} $_ ${BAT} $_ ${VOL} $_ ${DATE} $_ ${TIME} "
	sleep 10
done
