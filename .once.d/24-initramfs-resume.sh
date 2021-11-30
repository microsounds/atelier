#!/usr/bin/env sh

# configure resume from swap within initramfs

CONF='/etc/initramfs-tools/conf.d/resume'
KEY='RESUME'

# designate swap space for suspend to disk
UUID="$(sudo blkid | grep 'swap' | head -n 1 | tr ' ' '\n' | grep '^UUID')"

mkdir -p "${CONF%/*}"
conf-append "$KEY=$UUID" "$CONF"

