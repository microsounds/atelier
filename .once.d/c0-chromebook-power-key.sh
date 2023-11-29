#!/usr/bin/env sh

# systemd-logind chromebook hack
# disables power key so it can be remapped as Delete/F11

! is-chromebook && exit 0

conf-append 'HandlePowerKey=ignore' '/etc/systemd/logind.conf'
