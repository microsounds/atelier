#!/usr/bin/env sh

# quiet - shuts off fans for quiet operation (requires root)
# usage: quiet [options]
# 	-u     restores fan operation (automatically toggled)
# 	-h     displays this message

escape() { echo "$@" | sed 's/\//\\\//g'; }
eval_compose() { eval "$@"; echo "$@"; }

PROC="/proc/acpi/ibm/fan" # toggle automatically
if [ -z $1 ] && ! cat "$PROC" | grep -q "enabled"; then
	"$0" -u
	exit
fi

FAN="0"
TIMER="0"
VOL="35" # defaults
if [ ! -z $1 ]; then
	if [ "$1" = "-u" ]; then # restore settings
		FAN="auto"
		TIMER="10"
		VOL="100"
	else
		grep -E '^#\s+' "$0" | sed -e 's/# //g' -e "s/quiet/${0##*/}/g" # help
		exit 0
	fi
fi

if [ $(id -u) -ne 0 ]; then
	echo "You must have root permissions."
	exit 1
fi
amixer -q sset "Master" ${VOL}%
TMP=$(mktemp -q)
crontab -l > "$TMP"
sed -i "/$(escape $PROC)/d" "$TMP" # clean previous
eval_compose "echo \"watchdog $TIMER\" > $PROC" >> "$TMP"
eval_compose "echo \"level $FAN\" > $PROC" >> "$TMP"
for i in $(seq 1 5); do
	sed -i "/$(escape $PROC)/s/^/\\* /" "$TMP"
done
if [ "$FAN" != "auto" ]; then
	INS=$(grep -n "$PROC" "$TMP" | cut -d ':' -f1 | head -1) # comment
	sed -i "${INS}i # AUTOMATICALLY CONFIGURED (disable $PROC)" "$TMP"
else
	sed -i "/$(escape $PROC)/d" "$TMP" # disregard
fi
crontab "$TMP" # make changes permanent
rm "$TMP"
echo "Fan speed set to $FAN."
