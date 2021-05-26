#!/usr/bin/env sh

# grub configuration
# designate swap space for hibernation
# disable x86 mitigations

# not needed during unit testing
! is-container || exit 0

CONF='/etc/default/grub'
KEY='GRUB_CMDLINE_LINUX_DEFAULT'

UUID="$(/usr/sbin/blkid | grep 'swap' | head -n 1 | tr ' ' '\n' | grep '^UUID')"
OPTION="resume=$UUID loglevel=0 mitigations=off"

# append required key if it doesn't exist
grep -q "$KEY" < "$CONF" || echo "$KEY" | sudo tee -a "$CONF"
sed "/.*$KEY/c $KEY=\"$OPTION\"" < "$CONF" | sudo tee "$CONF"
sudo update-grub
