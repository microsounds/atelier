#!/usr/bin/env sh

# workaround for one of many chinese generic clone USB bluetooth dongles
# reporting being made by "Cambridge Silicon Radio, Ltd."
# these refuse to work at all unless they are reset once, because windows does
# this and they expect this behavior already
# more info: https://gist.github.com/nevack/6b36b82d715dc025163d9e9124840a07

lsusb -d '0a12:0001' || exit 0

cat <<- EOF | sudo tee '/etc/modprobe.d/csr8510-bluetooth.conf'
	# workaround for various chinese clone CSR8510 USB bluetooth dongles
	options btusb reset=1 enable_autosuspend=0
EOF
