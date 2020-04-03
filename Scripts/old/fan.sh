#!/usr/bin/env sh
# displays fan speed or system temps if fan is off

max=5700
speed=$(cat /proc/acpi/ibm/fan | sed -En 's/speed:\s+(.*)/\1/p')
fan=$(printf '%.1f%%' $(echo "($speed / $max) * 100" | bc -l))

if [ $speed -eq 0 ]; then # monitor temps
	fan='off'
	temps="$(acpi -tf | cut -d ' ' -f4)"
	cores=$(echo "$temps" | wc -l)
	avg=0
	for i in $temps; do
		avg=$(echo "scale=1; $avg + ($i / $cores)" | bc)
	done
	avg=" (${avg}°F)"
fi
echo "fan ${fan}$avg"
