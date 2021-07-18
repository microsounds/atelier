#!/usr/bin/env sh

# grub configuration
# append linux kernel tweaks

# not needed during unit testing
! is-container || exit 0

CONF='/etc/default/grub'
KEY='GRUB_CMDLINE_LINUX_DEFAULT'

UUID="$(sudo blkid | grep 'swap' | head -n 1 | tr ' ' '\n' | grep '^UUID')"

# designate swap space for suspend to disk
# ignore chatty startup text
# disable meltdown/spectre mitigations
# allow undervolt/overclock from userspace
OPTION="resume=$UUID loglevel=0 mitigations=off msr.allow_writes=on"

conf-append "$KEY=$OPTION" "$CONF"
sudo update-grub
