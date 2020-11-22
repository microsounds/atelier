#!/usr/bin/env sh

# bypass polkit in virt-manager
# permanently authenticates the current user

dpkg -s 'virt-manager' > /dev/null 2>&1 || exit 0
sudo adduser $(whoami) libvirt
