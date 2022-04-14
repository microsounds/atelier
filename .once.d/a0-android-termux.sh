#!/usr/bin/env sh

# android-termux.sh v0.9
# collection of hackjobs to enable basic functionality on termux for android
# some changes are ugly or incompatible with every other platform and will be
# applied manually so as to not pollute other scripts

uname -o | tr 'A-Z' 'a-z' | fgrep -q 'android' || exit 0

# install prerequisites
cat <<- EOF | sed 's/#.*$//g' | xargs pkg install -y
	wget git proot       # req'd for bootstrap
	clang binutils       # provides cpp
	openssl-tool openssh # nano-overlay
	busybox              # httpd
	n-t-roff-sc          # provides sc
	ledger
	bash-completion
EOF
# update existing
pkg update -y
# setup storage
yes y | termux-setup-storage

# prevent termux from sourcing .bashrc twice every login
# note: termux sources .bashrc before .profile on all logins
sed -ni ~/.profile -e '/## login shell/q;p'

# ~/.bashrc
# changes to shell startup, entry point for termux-chroot
! fgrep -q 'termux-chroot' < ~/.bashrc && {
	# allow use of standard file locations like /tmp
	sed -i ~/.bashrc \
		-e '1s/^/[ ! -z "$TERMUX" ] || { export TERMUX=1; exec termux-chroot; }\n/'

	# bash-completion is already sourced at startup
	sed -i ~/.bashrc -e '/bash-completion/d'

	# shorten output of path-gitstatus
	# break $PS1 into 2 lines on narrow displays
	sed -i ~/.bashrc -E \
		-e 's,(git_path.*)\),\1${TERMUX:+s}\),g' \
		-e 's,(PS1.*)\\\$,\1\${TERMUX:+\\n}\\\$,g'

	# make nano more bearable on narrow displays
	cat <<- EOF >> ~/.nanorc

		## changes for termux
		set minibar
		set stateflags
		unset softwrap
	EOF
}

# rewrite terminal ESC with octal ver as '\e' doesn't always work
# allow use of standard file descriptors on devices without root
script='s,\\e,\\33,g'
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

# save changes to .patch file
# use 'patch -p1' to reapply without re-running script
git meta diff --color=never > "$CONF/diff.patch"
