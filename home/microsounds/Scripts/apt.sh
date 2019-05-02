#!/usr/bin/env sh

# apt update notifier
# pushes a notification with a list of updated packages, if available
# --
# recommended use:
# periodically run 'apt-get update -qq' as root via cron job
# call this script from your own crontab
# 30 */2 * * * export DISPLAY=:0; /path/to/apt.sh

pkill -9 'notifyd'
id="$(lsb_release -si)"
icon= ; if [ "$id" != 'Debian' ]; then icon='software-update-available'; else icon='debian-logo'; fi
title="$id Software Update"
list="$(apt-get dist-upgrade -s -qq | grep -v 'Conf' | sed '1,4d')"
tr=5 # truncate after
IFS='
'
if [ ! -z "$list" ]; then
	num="$(echo "$list" | wc -l)"
	pkgs="You have $num new package(s).\n"
	for i in $list; do
		line="$(echo "$i" | tr -d '([]),')"
		if [ ! -z "$(echo "$line" | cut -d ' ' -f4 | grep -v '^[A-Z]')" ]; then
			pkgs="${pkgs}$(echo "$line" | cut -d ' ' -f2,4)\n" # upgrade
		else
			pkgs="${pkgs}$(echo "$line" | cut -d ' ' -f2,3)\n" # new
		fi
	done
	pkgs="${pkgs%\\n}" # trailing newline
	if [ $num -gt $tr ]; then
		pkgs="$(echo "$pkgs" | head -$((tr + 1)))\nand $((num - tr)) more."
	fi
	notify-send "$title" "$pkgs" -i "$icon" -u 'critical'
fi
