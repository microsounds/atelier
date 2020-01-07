#!/usr/bin/env sh
# dwm status bar
# provides formatted system information

_='・' # separator
fan_data='/proc/acpi/ibm/fan' # thinkpad acpi

# devices with active cooling and/or temperature sensors only
TEMP="$(acpi -tf | egrep -o '([0-9]+\.?){2}')"
if [ ! -z "$TEMP" ]; then
	TEMP="${TEMP}˚F"
	if [ ! -f $fan_data ]; then FAN="$TEMP";
	else
		FAN="$((($(egrep -o '[0-9]+' $fan_data) * 100) / 5700))"
		[ ! $FAN -eq 0 ] && FAN="Fan ${FAN}%" || FAN="$TEMP" # fan off
	fi
fi
NET="$(nmcli | fgrep 'connected' | sed 's/connected to //g' | head -1)"
[ ! -z "$NET" ] || NET="Airplane Mode"
BAT="Bat $(acpi -b | egrep -o '[0-9]+\%.*')"
SND="$(amixer get 'Master')"
VOL="Vol $(echo "$SND" | egrep -o '[0-9]+%' | head -1)"
[ ! -z "$(echo "$SND" | fgrep 'off')" ] && VOL="$VOL, muted"
TIME="$(date '+%l:%M%P' | sed 's/^ //g')"
for DAY in $(date '+%e' | sed 's/^ //g'); do
	case $DAY in
		1 | 21 | 31) DAY="${DAY}st";;
		2 | 22) DAY="${DAY}nd";;
		3 | 23) DAY="${DAY}rd";;
		*) DAY="${DAY}th"
	esac
done
DATE="$(date "+%a, %b $DAY")"
echo "${FAN:+${FAN}$_}${NET}$_${BAT}$_${VOL}$_${DATE}$_${TIME}"
