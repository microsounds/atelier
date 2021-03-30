#!/usr/bin/env sh

# chromebook i915 stability fix
# some extremely poorly-binned (read: defective) chromebook hardware can
# exhibit stability issues with the i915 display driver when making use of
# hardware acceleration
# eg. jumpy pointer, keyboard repeated inputs, system hanging and freezing
# this can be fixed by disabling panel-self refresh in i915

! is-chromebook && exit 0

sudo tee '/etc/modprobe.d/i915.conf' <<- EOF
	# disable panel-self refresh to mitigate system hangs and instability
	options i915 enable_psr=0
EOF
