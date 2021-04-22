#!/usr/bin/env sh

# collection of hackjobs to enable basic functionality on termux for android
# these changes are incompatible with standards compliant *NIX-likes
# and will be applied manually instead of added as edge cases within scripts

uname -o | tr 'A-Z' 'a-z' | fgrep -q 'android' || exit 0

mkdir -p ~/.termux

# install prerequisites
pkg install -y proot git openssl-tool openssh clang bash-completion

# allow use of standard file locations like /tmp
! fgrep -q 'termux-chroot' < ~/.profile && \
	sed '1s/^/termux-chroot\n/' -i ~/.profile

# allow use of standard file descriptors on devices without root
fd=0; for f in stdin stdout stderr; do
	script="$script;s,/dev/$f,/proc/self/fd/$fd,g"
	fd=$((fd + 1))
done
find ~/Scripts ~/.local -type f | xargs sed -e "$script" -i

# remove splash screen
rm -f /etc/motd

# reset meta upstream
~/.once.d/02-meta-config.sh

# strip unsupported nano features
sed -e '/scroller/d' -i ~/.nanorc

# import color scheme
colors='#include <colors/nightdrive.h>
cursor=FGCOLOR
foreground=FGCOLOR
background=BGCOLOR'
for f in $(seq 0 15); do
	colors="$colors
color$f=COLOR$f"
done
echo "$colors" | cpp -P > ~/.termux/colors.properties

# configure soft keys
cat <<- EOF > ~/.termux/termux.properties
	extra-keys-style = arrows-all
	extra-keys = [ \
		['ESC','~','/','HOME','UP','END','PGUP','DEL'], \
		['TAB','CTRL','ALT','LEFT','DOWN','RIGHT','PGDN','BKSP'] \
	]
EOF
