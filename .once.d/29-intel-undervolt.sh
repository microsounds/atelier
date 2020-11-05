#!/usr/bin/env sh

# install optional intel-undervolt daemon and systemd service
# a 100mV undervolt should be stable enough for Core i7 systems with terrible thermals
# undervolt daemon must still be configured and enabled manually with systemctl

TMP="/tmp/$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=7 count=1 2> /dev/null)"
REPO='https://github.com/kitsunyan/intel-undervolt'
CONF='/etc/intel-undervolt.conf'

finish() {
	rm -rf "$TMP"
	echo 'Done.'
	exit
}

echo "$0"
grep 'GenuineIntel' < /proc/cpuinfo > /dev/null || exit

trap finish 0 1 2 3 6
mkdir -v "$TMP"
if git clone "$REPO" "$TMP" && cd "$TMP"; then
	# keep existing configuration on reinstall
	[ -f "$CONF" ] && cp -v "$CONF" "$TMP"
	./configure --enable-systemd
	sudo make install
	sudo systemctl daemon-reload
fi
