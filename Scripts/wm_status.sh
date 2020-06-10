#!/usr/bin/env sh

# wm_status.sh v0.2
# non-blocking status bar daemon
# prints formatted status information to xsetroot

# option flags
for f in $(echo "${@#-}" | sed 's/./& /g'); do
	case $f in
		p) pad=' ';; # -p for extra padding
	esac
done

# FIFO location
prog="${0##*/}"
key="$(tr -cd 'a-z0-9' < /dev/urandom | head -c 7)"
FIFO="${XDG_RUNTIME_DIR:-/tmp}/${prog%.*}.$key"

abort() {
	rm -rf "$FIFO"
	xsetroot -name ''
	kill -- -$$
}

trap abort 0 1 2 3 6
mkfifo "$FIFO"

# thread loop
launch() {
	[ ! -e "$FIFO" ] && exit
	while :; do
		"$1"
		sleep "$2"
	done > "$FIFO" &
}

fan_speed() (
	# express fan speed in percent if supported
	sensors -u | egrep 'fan[0-9]+_input' | head -1 | while read -r _ rpm; do
		rpm=$(((${rpm%.*} * 100) / 5700))
		echo "FAN ${rpm}%"
	done
)

temps() (
	# express average CPU temperature in ˚F
	cores=$(grep -c '^proc' /proc/cpuinfo)
	sum=0; for f in $(sensors -u | egrep 'temp[0-9]+_input' | sort | tail -$cores \
	                             | sed 's/^ *//' | tr ' ' '\t' | cut -f2); do
		sum=$((sum + ${f%.*}))
	done
	temp="$(echo "scale=1; (($sum / $cores) * (9 / 5)) + 32" | bc)"
	echo "TEMP $temp˚F"
)

public_ip() (
	# get public IP (very slow)
	if ! ip="$(wget -q -O - 'https://ifconfig.me/ip')"; then
		ip="none"
	fi
	echo "IP $ip"
)

network() (
	# networking
	net="$(nmcli | fgrep 'connected' | sed 's/connected to //' | head -1)"
	echo "NET ${net:-Network Off}"
)

power() (
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
	echo "BAT $pct${btime_v:+, $btime_v}"
)

sound() (
	# sound mixer
	alsa="$(amixer get 'Master')"
	lvl="$(echo "$alsa" | egrep -o '[0-9]+%' | head -1)"
	[ ! -z "$(echo "$alsa" | fgrep 'off')" ] && lvl="$lvl, muted"
	echo "VOL Vol $lvl"
)

current_date() (
	# current date
	for day in $(date '+%-e'); do
		case $day in
			1 | 21 | 31) day="${day}st";;
			2 | 22) day="${day}nd";;
			3 | 23) day="${day}rd";;
			*) day="${day}th"
		esac
	done
	echo "DATE $(date '+%a, %b') $day"
)

current_time() (
	# current time
	echo "TIME $(date '+%-l:%M%P')"
)

# update every n seconds
launch fan_speed 30
launch temps 30
launch public_ip 15
launch network 15
launch power 30
launch sound 5
launch current_date 60
launch current_time 10

while read -r line; do
	# receive module output and append delimiter
	eval "${line%% *}=\"${line#* }・\""

	# conditional modules
	case "$FAN" in 0*) unset FAN;; esac # fan spindown
	# no internet
	case "$IP" in none*) unset IP;; esac
	case "$NET" in *disconnected) unset IP;; esac

	# compose status bar
	bar="${FAN-$TEMP}${IP}${NET}${BAT}${VOL}${DATE}${TIME}"

	# strip delimiter from the very end
	echo "'$pad$(echo "$bar" | sed 's/・$//')$pad'" | xargs xsetroot -name
done < "$FIFO"
