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
	while [ -e "$FIFO" ]; do
		"$1"
		sleep "$2"
	done > "$FIFO" &
}

fan_speed() (
	# express fan speed in percent power if supported
	sensors -u | egrep 'fan[0-9]+_input' | head -1 | while read -r _ rpm; do
		rpm=$(((${rpm%.*} * 100) / 5700))
		echo "FAN ${rpm}%💦"
	done
)

temps() (
	# express average CPU temperature in ˚F
	cores=$(grep -c '^proc' /proc/cpuinfo)
	sum=0; n=0; # don't assume # of cores is equal to # of sensors
	for f in $(sensors -u | egrep 'temp[0-9]+_input' | sort | tail -$cores \
	                      | sed 's/^ *//' | tr ' ' '\t' | cut -f2); do
		n=$((n + 1))
		sum=$((sum + ${f%.*}))
	done
	temp="$(echo "scale=1; (($sum / $n) * (9 / 5)) + 32" | bc)"
	echo "TEMP ∿$temp˚F"
)

public_ip() (
	# get public IP (very slow)
	ip="$(wget -q -O - 'https://ifconfig.me/ip')"
	echo "IP ${ip:-none}"
)

network() (
	# network manager status
	net="$(nmcli | fgrep 'connected' | sed 's/connected to //' | head -1)"
	echo "NET 📶 ${net:-Disabled}"
)

power() (
	# AC adapter / battery life
	acpi="$(acpi -b | tr -d ',' | head -1)"
	for f in $acpi; do case $f in
		*%) pct="$f";;
		*:*:*) btime="$f";;
	esac; done

	if [ ! -z "$btime" ]; then
		i=0; for f in h m; do # approximate time remaining
			i=$((i + 1))
			val="$(echo "$btime" | cut -d ':' -f$i | sed 's/^0//')"
			[ ! $val -eq 0 ] && btime_v="$btime_v$val$f"
		done
		for f in $acpi; do case $f in
			charged) btime_v="$btime_v till charged";;
			remaining) btime_v="$btime_v left";;
		esac; done
	fi
	echo "BAT ↯$pct${btime_v:+, $btime_v}"
)

sound() (
	# sound mixer
	alsa="$(amixer get 'Master')"
	lvl="$(echo "$alsa" | egrep -o '[0-9]+\%' | head -1)"
	echo "$alsa" | fgrep -q 'off' && mute="🔇"
	echo "VOL ${mute:-🔉}$lvl"
)

current_date() (
	# current date
	day="$(date '+%-e')"
	case $day in
		1 | 21 | 31) day="${day}st";;
		2 | 22) day="${day}nd";;
		3 | 23) day="${day}rd";;
		*) day="${day}th"
	esac
	echo "DATE $(date '+%a, %b') $day"
)

current_time() (
	# current time
	echo "TIME $(date '+%-l:%M%P')"
)

# update every n seconds
launch fan_speed 30
launch temps 30
#launch public_ip 15
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

	# strip delimiter from last module
	echo "'$pad$(echo "$bar" | sed 's/・$//')$pad'" | xargs xsetroot -name
done < "$FIFO"
