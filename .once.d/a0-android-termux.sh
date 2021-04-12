#!/usr/bin/env sh

# collection of hackjobs to enable basic functionality
# on Termux for Android

uname -o | tr 'A-Z' 'a-z' | fgrep -q 'android' || exit 0

pkg install -y proot git openssl-tool bash-completion
! fgrep -q 'termux-chroot' < ~/.profile && echo "termux-chroot" >> ~/.profile
find ~/Scripts ~/.local -type f | xargs sed -e 's,/dev/stdin,/proc/self/fd/0,g' -i
