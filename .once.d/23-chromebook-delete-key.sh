#!/usr/bin/env sh

# chromebook hack
# disables power key so it can be remapped as Delete/F11

read vendor < /sys/devices/virtual/dmi/id/sys_vendor
[ "$vendor" != 'GOOGLE' ] && exit 0

CONF='/etc/systemd/logind.conf'
KEY='HandlePowerKey'
OPTION='ignore'

echo "$0"
grep -q "$KEY" "$CONF" || echo "$KEY" | sudo tee -a "$CONF"
sudo sed -i "/.*$KEY/c $KEY=$OPTION" "$CONF"
