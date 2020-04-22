#!/usr/bin/env sh
# dwm status bar
# provides formatted system information

_='・' # separator character
fan_data='/proc/acpi/ibm/fan' # thinkpad acpi

# -p for extra padding
for f in $(echo "$@" | sed 's/./& /g'); do
	case $f in p) PAD=' ';; esac
done

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
NET="$(nmcli | fgrep 'connected' | sed 's/connected to //' | head -1)"
[ ! -z "$NET" ] || NET="Network Off"

# power management
acpi="$(acpi -b | egrep -o '[0-9]+\%.*')"
pct="$(echo "$acpi" | egrep -o '[0-9]+%' | head -1)"

# ignore blank, 'Unknown' or 'Charging at zero rate' values
if [ "$acpi" != "$pct" ] && ! echo "$acpi" | egrep -q '(Unknown|zero)'; then
	btime="$(echo "$acpi" | egrep -o '([0-9]+:?)+' | tail -1)"
	i=0; for f in h m; do # rewrite time remaining as approximation
		i=$((i + 1))
		val="$(echo "$btime" | cut -d ':' -f$i | sed 's/^0//')"
		[ ! $val -eq 0 ] && btime_v="$btime_v$val$f"
	done
	for f in $acpi; do case $f in
		charged) btime_v="$btime_v till charged";;
		remaining) btime_v="$btime_v left";;
	esac; done
fi
BAT="Bat $pct${btime_v:+, $btime_v}"

# audio
sound="$(amixer get 'Master')"
VOL="Vol $(echo "$sound" | egrep -o '[0-9]+%' | head -1)"
[ ! -z "$(echo "$sound" | fgrep 'off')" ] && VOL="$VOL, muted"

# time/date
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

echo "${PAD}${FAN:+${FAN}$_}${NET}$_${BAT}$_${VOL}$_${DATE}$_${TIME}${PAD}"
