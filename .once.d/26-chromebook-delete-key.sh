#!/usr/bin/env sh

# systemd-logind chromebook hack
# disables power key so it can be remapped as Delete/F11

read vendor < /sys/devices/virtual/dmi/id/sys_vendor
[ "$vendor" != 'GOOGLE' ] && exit 0

CONF='/etc/systemd/logind.conf'
KEY='HandlePowerKey'
OPTION='ignore'

# append required key if it doesn't exist
grep -q "$KEY" "$CONF" || echo "$KEY" | sudo tee -a "$CONF"
sed "/.*$KEY/c $KEY=$OPTION" < "$CONF" | sudo tee "$CONF"
echo "You must restart logind for changes to take effect."
