#!/usr/bin/env sh

# systemd tweaks

# limit systemd start/stop job timers to 10 seconds
CONF='/etc/systemd/system.conf'

for f in Start Stop; do
	KEY="DefaultTimeout${f}Sec"
	OPTION='10s'
	# append required key if it doesn't exist
	grep -q "$KEY" < "$CONF" || echo "$KEY" | sudo tee -a "$CONF"
	sed "/.*$KEY/c $KEY=$OPTION" < "$CONF" | sudo tee "$CONF"
done
