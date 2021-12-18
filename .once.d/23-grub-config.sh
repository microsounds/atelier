#!/usr/bin/env sh

# grub configuration
# append linux kernel tweaks

CONF='/etc/default/grub'
KEY='GRUB_CMDLINE_LINUX_DEFAULT'

# not needed during unit testing
! is-container || exit 0

# probably an ARM device using u-boot
[ -f "$CONF" ] || exit 0

unset OPTION
# ignore chatty startup text
OPTION="$OPTION loglevel=0"
# disable meltdown/spectre mitigations
OPTION="$OPTION mitigations=off"
# allow undervolt/overclock from userspace
OPTION="$OPTION msr.allow_writes=on"

conf-append "$KEY=$OPTION" "$CONF"
sudo update-grub
