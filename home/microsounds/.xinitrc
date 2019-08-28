#!/usr/bin/env sh
## ~/.xinitrc: xinit user configuration

xrdb $HOME/.Xresources

# dwm status bar
while true; do
	_='・' # separator
	if [ ! -f '/proc/acpi/ibm/fan' ]; then FAN="N/A"; # strange environment
	else
		FAN="$((($(cat /proc/acpi/ibm/fan | egrep -o '[0-9]+') * 100) / 5300))"
		if [ "$FAN" -eq 0 ]; then
			FAN="$(acpi -tf | egrep -o '[0-9]+\.[0-9]')" # fans off
			[ -z "$FAN" ] && FAN="N/A" || FAN="${FAN}˚F"
		else
			FAN="fan ${FAN}%"
		fi
	fi
	NET="$(nmcli | grep -w 'connected' | sed 's/connected to //g')"
		[ ! -z "$NET" ] || NET="disconnected"
	VOL="vol $(amixer get 'Master' | egrep -o [[0-9]+%] | sed 1q | tr -d '[]')"
	BAT="bat $(acpi -b | cut -d ' ' -f 4-6 | sed 's/,$//g' | sed 's/[0]+\://g')"
	TIME="$(date '+%l:%M%P')"
	DAY="$(date '+%e')"
	case $DAY in
		1 | 21 | 31) DAY="${DAY}st";;
		2 | 22) DAY="${DAY}nd";;
		3 | 23) DAY="${DAY}rd";;
		*) DAY="${DAY}th"
	esac
	DATE="$(date "+%a, %b $DAY")"
	xsetroot -name "${FAN} $_ ${NET} $_ ${BAT} $_ ${VOL} $_ ${DATE} $_ ${TIME}"
	sleep 10
done &

exec dwm
