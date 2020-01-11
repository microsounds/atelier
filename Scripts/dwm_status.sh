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
# networking
NET="$(nmcli | fgrep 'connected' | sed 's/connected to //g' | head -1)"
[ ! -z "$NET" ] || NET="Airplane Mode"
# power management
acpi="$(acpi -b | egrep -o '[0-9]+\%.*')"
pct="$(echo "$acpi" | egrep -o '[0-9]+%' | head -1)"
if [ $pct != '100%' ]; then
	for btime in "$(echo "$acpi" | egrep -o '([0-9]+:?)+' | tail -1)"; do
		i=0; for f in h m; do # rewrite time remaining into pretty output
			i=$((i + 1))
			val="$(echo "$btime" | tr ':' ' ' | cut -d ' ' -f$i | sed 's/^0*//')"
			[ ! -z "$val" ] || continue # fields empty?
			[ $val -ne 0 ] && btime_v="$btime_v$val$f"
		done
		for f in $acpi; do case $f in
				charged) BAT="$btime_v till charged";;
				remaining) BAT="$btime_v left";;
			esac
		done
	done
fi
BAT="Bat $pct${BAT:+, $BAT}"
# audio
sound="$(amixer get 'Master')"
VOL="Vol $(echo "$sound" | egrep -o '[0-9]+%' | head -1)"
[ ! -z "$(echo "$sound" | fgrep 'off')" ] && VOL="$VOL, muted"
# time
TIME="$(date '+%-l:%M%P')"
for day in $(date '+%-e'); do
	case $day in
		1 | 21 | 31) day="${day}st";;
		2 | 22) day="${day}nd";;
		3 | 23) day="${day}rd";;
		*) day="${day}th"
	esac
done
DATE="$(date '+%a, %b') $day"
echo "${FAN:+${FAN}$_}${NET}$_${BAT}$_${VOL}$_${DATE}$_${TIME}"
