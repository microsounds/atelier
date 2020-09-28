#!/usr/bin/env sh

# bypass polkit in virt-manager
# permanently authenticates the current user

echo "$0"
dpkg -s 'virt-manager' > /dev/null 2>&1 && sudo adduser $(whoami) libvirt
