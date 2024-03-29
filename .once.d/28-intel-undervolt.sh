#!/usr/bin/env sh

# install optional intel-undervolt daemon and systemd service
# works only with 4th-gen Haswell or newer architectures
# undervolt daemon must still be configured and enabled manually with systemctl

# Usage Notes
# -100mV is usually enough to control thermal throttling or runaway thermals
# on aging 2012-2018 hyper-threaded Intel desktop CPUs mfd. with non-soldered
# heat spreaders that, over time, degrade their thermal performance at
# sustained full load unless you physically remove the heat spreader at your
# own risk to repaste it or increase physical cooler size.

# Note on Skylake and newer
# 7th-gen Skylake or newer architectures may or may not have had their
# undocumented undervolt instructions purposefully disabled with recent
# microcode updates, the same "security mitigations" that demonstrably
# kneecap performance.
# Intel has tried their hardest to turn a decade's worth of their products
# into literal e-waste, you have been warned.

REPO='https://github.com/kitsunyan/intel-undervolt'
CONF='/etc/intel-undervolt.conf'
TMP="$(mk-tempdir)"

finish() {
	rm -rf "$TMP"
	echo 'Done.'
	exit
}

# not needed during unit testing
! is-container || exit 0

grep 'GenuineIntel' < /proc/cpuinfo > /dev/null || exit

trap finish 0 1 2 3 6 15
mkdir -v "$TMP"
if git clone "$REPO" "$TMP" || exit 1 && cd "$TMP"; then
	# keep existing configuration on reinstall
	[ -f "$CONF" ] && cp -v "$CONF" "$TMP"
	./configure --enable-systemd
	sudo make install
	sudo systemctl daemon-reload
fi
