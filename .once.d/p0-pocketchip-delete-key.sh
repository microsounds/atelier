#!/usr/bin/env sh

# systemd-logind pocketchip hack
# disables power key so it can be remapped as Super_L

! is-ntc-chip && exit 0

conf-append 'HandlePowerKey=ignore' '/etc/systemd/logind.conf'
