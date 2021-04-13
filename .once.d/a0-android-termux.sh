#!/usr/bin/env sh

# collection of hackjobs to enable basic functionality on android termux

uname -o | tr 'A-Z' 'a-z' | fgrep -q 'android' || exit 0

pkg install -y proot git openssl-tool openssh bash-completion

# allow use of standard file locations like /tmp
! fgrep -q 'termux-chroot' < ~/.profile && echo "termux-chroot" >> ~/.profile

# allow use of stdin on devices without root
find ~/Scripts ~/.local -type f | xargs sed -e 's,/dev/stdin,/proc/self/fd/0,g' -i
