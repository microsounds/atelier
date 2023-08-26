#!/usr/bin/env sh

# collection of systemd/freedesktop-related tweaks

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

# gnome-keyring-daemon causes startup hangs related to libpam in some GTK3-based apps
is-installed gnome-keyring \
	&& yes y | sudo apt-get autoremove --purge gnome-keyring*
