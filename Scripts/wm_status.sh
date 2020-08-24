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
key="$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=7 count=1 2> /dev/null)"
FIFO="${XDG_RUNTIME_DIR:-/tmp}/.${prog%.*}.$key"

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
	# express fan speed in RPM if supported
	sensors -u | egrep 'fan[0-9]+_input' | head -n 1 | while read -r _ rpm; do
		rpm="${rpm%.*}"
		if [ $rpm -gt 999 ]; then
			rpm="$(echo "scale=1; $rpm / 1000" | bc)k"
		fi
		echo "FAN ${rpm}↻"
	done
)

temps() (
	# express average CPU temperature in ˚F if supported
	data="$(sensors -u coretemp-isa-0000)" || return # not supported
	unset sum n
	for f in $(echo "$data" | egrep 'temp[0-9]+_input' |
		tr -d ' ' | tr -s ':' '\t' | cut -f2); do
		n=$((n + 1))
		sum=$((sum + ${f%.*}))
	done
	temp="$(echo "scale=1; (($sum / $n) * 1.8) + 32" | bc)"
	echo "TEMP ∿$temp˚F"
)

cpu_speed() (
	# express average CPU clock speed
	unset sum n
	for f in $(fgrep 'MHz' < '/proc/cpuinfo' |
		tr -d ' ' | tr -s ':' '\t' | cut -f2); do
		n=$((n + 1))
		sum=$((sum + ${f%.*}))
	done
	clk=$((sum / n))
	[ $clk -gt 999 ] && clk="$(echo "scale=2; $clk / 1000" | bc)GHz" ||
		clk="${clk}MHz"
	echo "CPU $clk"
)

public_ip() (
	# get public IP (very slow)
	ip="$(wget -q -O - 'https://ifconfig.me/ip')"
	echo "IP ${ip:-none}"
)

network() (
	# show networking status for first active connection
	net="$(nmcli -t device | grep '[^dis]connected' | head -n 1 | \
		cut -d ':' -f2,4 | sed 's/:/& /')"
	if [ -z "$net" ]; then # disconnected or networking disabled
		net="$(nmcli -t networking)"
		net="$(echo "${net%${net#?}}" | tr 'a-z' 'A-Z')${net#?}"
	fi
	echo "NET 📶 ${net}"
)

power() (
	# battery life / AC adapter status if supported
	acpi="$(acpi -b | tr -d ',' | head -n 1)"
	[ ! -z "$acpi" ] || return # not supported
	for f in $acpi; do case $f in
		unavailable) return;; # not supported
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
	# sound mixer status
	alsa="$(amixer get 'Master')"
	lvl="$(echo "$alsa" | egrep -o '[0-9]+\%' | head -n 1)"
	echo "$alsa" | fgrep -q 'off' && mute='🔇'

	# headphone status
	for f in $(pactl list sinks | tr 'A-Z' 'a-z' | fgrep 'active port') ; do
		case $f in *headphones) aux=' ☊';; esac
	done
	echo "VOL ${mute:-🔉}$lvl$aux"
)

current_date() (
	# calculate days since a specific new moon
	# divide by length of lunar cycle
	# express currently elapsed cycle progress in percent
	now=$(date '+%s')
	known=633381600 # Jan 26th, 1990 was a new moon
	cycle=$(echo "scale=2; (($now - $known) / 86400) / 29.53" | bc)
	cycle=${cycle#*.} # absolute value
	# map progress to an available glyph
	phase='🌕 🌖 🌗 🌘 🌑 🌑 🌒 🌓 🌔 🌕'
	map=$(((${cycle#0} / 10) + 1))
	moon=$(echo "$phase" | tr ' ' '\n' | tail -n +$map | head -n 1)

	# current date
	timest="$(date '+%-e %a, %b x')"
	day="${timest%% *}"
	case $day in
		1 | [!1]1) day="${day}st";;
		2 | [!1]2) day="${day}nd";;
		3 | [!1]3) day="${day}rd";;
		*) day="${day}th"
	esac
	echo "DATE $moon ${timest#* }" | sed "s/x/$day/"
)

current_time() (
	# current time
	echo "TIME $(date '+%-l:%M%P')"
)

# update every n seconds
launch fan_speed 10
launch temps 15
#launch cpu_speed 5
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
	bar="${FAN-$TEMP}${CPU}${IP}${NET}${BAT}${VOL}${DATE}${TIME}"

	# strip delimiter from last module
	echo "'$pad$(echo "$bar" | sed 's/・$//')$pad'" | xargs xsetroot -name
done < "$FIFO"
