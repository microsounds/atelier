#!/usr/bin/env sh

# install optional intel-undervolt daemon and systemd service
# works only with 4th-gen Haswell or newer architectures
# undervolt daemon must still be configured and enabled manually with systemctl

# Usage Notes
# -100mV is usually enough to control thermal throttling or runaway thermals
# on aging 2012-2018 hyper-threaded Intel desktop CPUs mfd. with non-soldered
# heat spreaders that, over time, degrade their thermal performance at
# sustained full load unless you delid or increase physical cooler size.

TMP="/tmp/$(tr -cd 'a-z0-9' < /dev/urandom | dd bs=7 count=1 2> /dev/null)"
REPO='https://github.com/kitsunyan/intel-undervolt'
CONF='/etc/intel-undervolt.conf'

finish() {
	rm -rf "$TMP"
	echo 'Done.'
	exit
}

grep 'GenuineIntel' < /proc/cpuinfo > /dev/null || exit

trap finish 0 1 2 3 6
mkdir -v "$TMP"
if git clone "$REPO" "$TMP" || exit 1 && cd "$TMP"; then
	# keep existing configuration on reinstall
	[ -f "$CONF" ] && cp -v "$CONF" "$TMP"
	./configure --enable-systemd
	sudo make install
	sudo systemctl daemon-reload
fi
