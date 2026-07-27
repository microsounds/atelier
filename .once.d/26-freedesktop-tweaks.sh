#!/usr/bin/env sh

# snowballing collection of systemd/freedesktop-related tweaks

# limit systemd start/stop job timers to 10 seconds
for f in Start Stop; do
	conf-append "DefaultTimeout${f}Sec=10s" '/etc/systemd/system.conf'
done

# limit size of journald logs
conf-append 'SystemMaxUse=20M' '/etc/systemd/journald.conf'

# replace hybrid-sleep with hibernate+reboot for quick dualboots
user-confirm 'Replace systemd hybrid-sleep mode with hibernate+reboot?' && {
	conf-append 'HybridSleepMode=reboot' '/etc/systemd/sleep.conf'
	conf-append 'HibernateDelaySec=0s' '/etc/systemd/sleep.conf'
}

# allow unprivileged users to view kernel syslog
conf-append 'kernel.dmesg_restrict = 0' '/etc/sysctl.conf'

# purge GNOME desktop trash that cause 25sec startup hangs in some GTK3 apps
# gnome-keyring-daemon hangs chromium looking for libpam
# xdg-desktop-portal-gtk hangs pavucontrol, OBS, and other apps
yes y | sudo apt-get autoremove --purge gnome-keyring* xdg-desktop-portal*

# install symlink to locally maintained system-sleep hooks
sudo ln -sfv \
	"$(realpath ~/.local/lib/systemd-sleep)" '/lib/systemd/system-sleep'

# ensure pulseaudio isn't installed on machine
systemctl --user enable pipewire pipewire-pulse
systemctl --user disable pulseaudio.service pulseaudio.socket
yes y | sudo apt-get autoremove --purge pulseaudio

# sideloads non-free AAC codec support for supported bluetooth audio devices,
# deliberately excluded from libspa-0.2-bluetooth on Debian 12+
# See 'https://tookmund.com/2024/02/aac-and-debian' and
# 'https://blog.fernvenue.com/archives/airpods-pro-2-on-debian/' for more info.
SOURCE='https://blog.fernvenue.com/others/libspa-codec-bluez5-aac_0.3.65_amd64.deb'
TEMP="$(mk-tempdir)"

! is-installed libspa-codec-bluez5-aac && {
	wget -O "$TEMP" "$SOURCE"
	sudo dpkg -i "$TEMP"
	rm -rf "$TEMP"
	systemctl --user restart wireplumber pipewire pipewire-pulse | :
}
