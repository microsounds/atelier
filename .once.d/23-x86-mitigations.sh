#!/usr/bin/env sh

# disable x86 mitigations

CONF='/etc/default/grub'
KEY='GRUB_CMDLINE_LINUX_DEFAULT'
OPTION='quiet mitigations=off'

# append required key if it doesn't exist
grep -q "$KEY" "$CONF" || echo "$KEY" | sudo tee -a "$CONF"
sed "/.*$KEY/c $KEY=\"$OPTION\"" < "$CONF" | sudo tee "$CONF"
sudo update-grub
