#!/usr/bin/env sh

# grub configuration
# designate swap space for hibernation
# disable x86 mitigations

# not needed during unit testing
! is-container || exit 0

CONF='/etc/default/grub'
KEY='GRUB_CMDLINE_LINUX_DEFAULT'

UUID="$(sudo blkid | grep 'swap' | head -n 1 | tr ' ' '\n' | grep '^UUID')"
OPTION="resume=$UUID loglevel=0 mitigations=off"

conf-append "$KEY=$OPTION" "$CONF"
sudo update-grub
