#!/usr/bin/env sh

# ntc pocketchip hack
# since debian stretch, network-manager becomes extremely chatty in tty1 if
# random mac address randomization is enabled

! is-ntc-chip && exit 0

cat <<- EOF | sudo tee -a /etc/NetworkManager/NetworkManager.conf
	# $0
	# changes required since debian stretch
	[connection]
	wifi.mac-address-randomization=1

	[device]
	wifi.scan-rand-mac-address=no
EOF
