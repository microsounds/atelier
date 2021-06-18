#!/usr/bin/env sh

# NetworkManager tweaks

# not needed during unit testing
! is-container || exit 0

# don't wait on networking during startup
sudo systemctl disable NetworkManager-wait-online.service

# allow NetworkManager to manage wired devices from /etc/network/interfaces
conf-append 'managed=true' '/etc/NetworkManager/NetworkManager.conf'
sudo systemctl restart NetworkManager
