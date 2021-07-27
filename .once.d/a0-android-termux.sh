#!/usr/bin/env sh

# collection of hackjobs to enable basic functionality on termux for android
# these changes are incompatible with standards compliant *NIX-likes
# and will be applied manually so as to not pollute other scripts

uname -o | tr 'A-Z' 'a-z' | fgrep -q 'android' || exit 0

# install prerequisites
cat <<- EOF | sed 's/#.*$//g' | xargs pkg install -y
	wget git proot       # req'd for bootstrap
	clang                # provides cpp
	openssl-tool openssh # nano-overlay
	ledger
	bash-completion
EOF
# setup storage
yes y | termux-setup-storage

# termux-chroot
# allow use of standard file locations like /tmp
# note: termux sources .bashrc before .profile on all logins
! fgrep -q 'termux-chroot' < ~/.bashrc && \
	sed -i ~/.bashrc -e \
		'1s/^/[ ! -z "$TERMUX" ] || { export TERMUX=1; exec termux-chroot; }\n/'

# prevent termux from sourcing .bashrc twice every login
sed -i ~/.profile -e '/X server/q'

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

# termux-specific
# install fonts
CONF="$HOME/.termux"
SOURCE='https://packages.debian.org/sid/all/fonts-go/download'
SOURCE="$(wget -q -O - "$SOURCE" | egrep -o '<a href=.*>' \
	| tr '"' '\t' | cut -f2 | grep 'deb$' | head -n 1)"
DEB="${SOURCE##*/}"

mkdir -p "$CONF"
if wget "$SOURCE" -O "$CONF/$DEB" || exit 1; then
	sleep 1 # termux will crash otherwise
	ar -p "$CONF/$DEB" 'data.tar.xz' | xz -d \
		| tar -xO --wildcards '*Go-Mono.ttf' > "$CONF/font.ttf"
	rm -f "$CONF/$DEB"
fi

# import color scheme
colors='#include <colors/nightdrive.h>
cursor=FGCOLOR
foreground=FGCOLOR
background=BGCOLOR'
for f in $(seq 0 15); do
	colors="$colors
color$f=COLOR$f"
done
echo "$colors" | cpp -P > "$CONF/colors.properties"

# configure soft key layout
cat <<- EOF > "$CONF/termux.properties"
	extra-keys-style = arrows-all
	extra-keys = [ \
		[ ESC, '~',  '/', HOME, UP,   END,   PGUP, DEL  ], \
		[ TAB, CTRL, ALT, LEFT, DOWN, RIGHT, PGDN, BKSP ] \
	]
EOF
