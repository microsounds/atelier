#!/usr/bin/env sh

# collection of hackjobs to enable basic functionality on android termux

uname -o | tr 'A-Z' 'a-z' | fgrep -q 'android' || exit 0

pkg install -y proot git openssl-tool openssh bash-completion

# allow use of standard file locations like /tmp
# termux loads .bashrc before .profile
! fgrep -q 'termux-chroot' < ~/.bashrc && \
	sed '1s/^/[ $SHLVL -lt 2 ] \&\& termux-chroot \&\& exit\n/' -i ~/.bashrc

# allow use of stdin on devices without root
find ~/Scripts ~/.local -type f | xargs sed -e 's,/dev/stdin,/proc/self/fd/0,g' -i

# remove splash screen
rm -f /etc/motd

# setup dotfile upstream
~/.once.d/02-meta-config.sh
