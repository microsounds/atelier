#!/usr/bin/env sh
# dwm status bar
# provides formatted system information

_='・' # separator
fan_data='/proc/acpi/ibm/fan' # thinkpad acpi

while true; do
	TEMP="$(acpi -tf | egrep -o '([0-9]+\.?){2}')˚F"
	if [ ! -f $fan_data ]; then FAN="$TEMP"; # get fan speed
	else
		FAN="$((($(egrep -o '[0-9]+' $fan_data) * 100) / 5300))"
		[ ! $FAN -eq 0 ] && FAN="Fan ${FAN}%" || FAN="$TEMP"
	fi
	NET="$(nmcli | grep 'connected' | sed 's/connected to //g' | sed -n 1p)"
	[ ! -z "$NET" ] || NET="No Network"
	BAT="Bat $(acpi -b | egrep -o '[0-9]+\%.*')"
	VOL="Vol $(amixer get 'Master' | egrep -o '[0-9]+%' | sed 1q)"
	amixer get 'Master' | grep 'off' && VOL="${VOL}, muted"
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
