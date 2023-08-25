#!/usr/bin/env sh

# wm_status.sh v0.4
# non-blocking status line daemon
# prints formatted status information to stdout

# global option flags
for f in $(echo "${@#-}" | sed 's/./& /g'); do
	case $f in
		p) pad=' ';; # -p for extra padding
		q) quote='"';; # -q to enquote output for xargs
		m) invert=1;; # -m for reverse video glyphs
	esac
done

# global delimiter
delim='・'

# generate sed script for final output formatting
IFS=''
script="s/${delim}$//" # strip trailing delimiter
for f in $pad $quote; do # surround output with special characters
	script="$script;s/^/${f}&/;s/$/&${f}/"
done
unset IFS

# FIFO locations
prog="${0##*/}"
key="$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=7 count=1 2> /dev/null)"
FIFO="${XDG_RUNTIME_DIR:-/tmp}/.${prog%.*}.$key"

# notification FIFO written to by notify-send
NFIFO="$HOME/.notify"

abort() {
	rm -rf "$FIFO" "$NFIFO"
	echo "[!] ${0##*/} terminated unexpectedly" | sed -e "$script"
	kill -- -$$ > /dev/null 2>&1
}

trap abort 0 1 2 3 6 15
mkfifo "$FIFO" "$NFIFO"

# monitor and redirect notifications from notify-send
# prevent named pipe from closing
{	while :; do
		while read -r msg < "$NFIFO"; do
			echo "MSG $msg"
		done
	done
} > "$FIFO" &

# thread loop
launch() {
	while :; do
		sleep "$2" &
		"$1"
		wait
	done > "$FIFO" &
}

# individual threads
ssh_agent() (
	# list number of active keys stored in agent
	num=$(ssh-add -l) && \
		num=$(echo "$num" | wc -l) || unset num
	echo "SSH ⚿×${num:-none}"
)

fan_speed() (
	# express fan speed in RPM if supported
	sensors -u | egrep 'fan[0-9]+_input' | head -n 1 | while read -r _ rpm; do
		rpm="${rpm%.*}"
		if [ ${#rpm} -gt 3 ]; then
			rpm="$(echo "scale=1; $rpm / 1000" | bc)k"
		fi
		echo "FAN ${rpm}↻"
	done
)

weather() (
	# get geolocated current weather with wttr.in (very slow)
	# bypass their caching which returns stale data when using en.wttr.in
	fmt='%c%f'
	locales="am ar af be bn ca da de el et fr fa gl hi hu ia id it lt mg \
	nb nl oc pl pt-br ro ru ta tr th uk vi zh-cn zh-tw az bg bs cy cs eo \
	es eu fi ga hi hr hy is ja jv ka kk ko ky lv mk ml mr nl fy nn pt pt-br \
	sk sl sr sr-lat sv sw te uz zh zu he"
	sel="$(echo "$locales" | tr -s '\t\n ' '\n' | shuf | head -n 1)"

	wttr="$(wget --timeout=2 -q -O - "http://$sel.wttr.in/?u&format=$fmt" | tr -d '+ ')"
	case "$wttr" in Unknown*) unset wttr;; esac # wttr.in API is down
	echo "WTTR ${wttr:-none}"
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
	echo "TEMP ∿${temp%*.0}°F"
)

cpu_speed() (
	# express average CPU clock speed
	unset sum n
	for f in $(fgrep 'MHz' < '/proc/cpuinfo' | tr -d ' ' \
		| tr -s ':' '\t' | cut -f2); do
		n=$((n + 1))
		sum=$((sum + ${f%.*}))
	done
	clk=$((sum / n))
	[ ${#clk} -gt 3 ] && clk="$(echo "scale=2; $clk / 1000" | bc)G" \
		|| clk="${clk}M"
	echo "CPU ${clk}Hz"
)

public_ip() (
	# get public IP address (very slow)
	ip="$(dig @resolver1.opendns.com myip.opendns.com +short 2> /dev/null)"
	echo "IP ☍${ip:-none}"
)

network() (
	# show networking status for first active connection
	net="$(nmcli -t device | grep '[^dis]connected' | head -n 1 | \
		cut -d ':' -f2,4 | sed 's/:/& /')"
	if [ -z "$net" ]; then # disconnected or networking disabled
		net="$(nmcli -t networking)"
		net="$(echo "${net%${net#?}}" | tr 'a-z' 'A-Z')${net#?}"
	fi
	ico='📶' # connected but no internet
	ping -c 1 'google.com' > /dev/null 2>&1 || ico='⛔'
	echo "NET $ico $net"
)

power() (
	# extract battery life / AC adapter status if supported
	acpi="$(acpi -b | tr -d ',' | head -n 1)" 2> /dev/null
	[ ! -z "$acpi" ] || return # not supported
	for f in $acpi; do case $f in
		unavailable) return;; # not supported
		*%) pct="$f";;
		*:*:*) btime="$f";;
	esac; done

	# rewrite approx. time remaining if available
	if [ ! -z "$btime" ]; then
		i=0; for f in h m; do
			i=$((i + 1))
			val="$(echo "$btime" | cut -d ':' -f$i | sed 's/^0//')"
			[ ! $val -eq 0 ] && btime_v="$btime_v$val$f"
		done
		for f in $acpi; do case $f in
			charged) btime_v="$btime_v 'til charged";;
			remaining) btime_v="$btime_v left";;
		esac; done
	fi
	echo "BAT ↯$pct${btime_v:+, $btime_v}"
)

sound() (
	# sound mixer status
	alsa="$(amixer get 'Master')"
	lvl="$(echo "$alsa" | egrep -o '[0-9]+\%' | head -n 1)"
	ico='🔉' # normal/muted icon
	echo "$alsa" | fgrep -q 'off' && ico='🔇'

	# headphone status
	for f in $(pactl list sinks | tr 'A-Z' 'a-z' | fgrep 'active port') ; do
		case $f in *headphones) aux=' ☊';; esac
	done
	echo "VOL $ico$lvl$aux"
)

current_date() (
	# current date
	echo "DATE $(moonphase-date ${invert+-i})"
)

current_time() (
	# current time
	echo "TIME $(date '+%-l:%M%P')"
)

# update every n seconds
launch ssh_agent 5
launch fan_speed 10
launch temps 15
launch weather 60
#launch cpu_speed 1
#launch public_ip 30
launch network 15
launch power 15
launch sound 5
launch current_date 60
launch current_time 10

while read -r module data; do
	# receive module output and append delimiter
	eval "$module=\"$data$delim\""

	# stop everything to display notification
	# expected format: '[n display sec] [message]'
	[ ! -z "$MSG" ] &&
		echo "${MSG#* }" | sed -e "$script" && sleep "${MSG%% *}" && unset MSG

	# conditionally delete non-message modules
	case "$data" in
		0*|*none) eval "unset $module";; # fan spindown/no internet
		*abled) unset IP;; # no internet
	esac

	# compose all available modules
	bar="${SSH}${FAN:-$TEMP}${CPU}${NET}${IP}${BAT}${VOL}${WTTR}${DATE}${TIME}"

	# output final formatted status line
	echo "$bar" | sed -e "$script"

done < "$FIFO"
