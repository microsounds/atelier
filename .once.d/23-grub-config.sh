#!/usr/bin/env sh

# GRUB2 configuration

CONF='/etc/default/grub'

# not needed during unit testing
! is-container || exit 0

# probably an ARM device using u-boot
[ -f "$CONF" ] || exit 0

# append linux kernel tweaks
unset OPTION
KEY='GRUB_CMDLINE_LINUX_DEFAULT'
# ignore chatty startup text
OPTION="$OPTION loglevel=0"
# disable meltdown/spectre mitigations
OPTION="$OPTION mitigations=off"
# allow undervolt/overclock from userspace
OPTION="$OPTION msr.allow_writes=on"
conf-append "$KEY=$OPTION" "$CONF"

# dual-boot: enable os-prober by default
conf-append "GRUB_DISABLE_OS_PROBER=false" "$CONF"

# dual-boot: remember last OS chosen between reboots
conf-append "GRUB_INIT_TUNE=1000 720 1" "$CONF"
conf-append "GRUB_SAVEDEFAULT=true" "$CONF"
conf-append "GRUB_DEFAULT=saved" "$CONF"
sudo update-grub
