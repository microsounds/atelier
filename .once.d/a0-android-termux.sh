#!/usr/bin/env sh

# android-termux.sh v1.1

# collection of hackjobs to enable basic functionality on Termux for Android
# and paper over inconsistencies between standard Linux environments and the
# ones provided by unrooted Android devices
# some changes are ugly or incompatible with every other platform and will be
# applied manually so as to not pollute other scripts

! is-termux && exit 0

# install prerequisites
cat <<- EOF | sed 's/#.*$//g' | xargs apt install -y
	wget git                      # req'd for bootstrap
	clang binutils                # provides cpp
	openssl-tool openssh iproute2 # nano-overlay, ssh server
	termux-api jq                 # provides fingerprint auth
	busybox                       # httpd
	n-t-roff-sc                   # provides sc
	man moreutils                 # misc comforts
	ledger gnuplot
	imagemagick
	bash-completion
	libqrencode
EOF

# update existing
for f in update upgrade autoremove autoclean clean; do
	yes y | apt $f
done

# setup hardware keystore with 'default' key for use with termux-ssh-askpass
# assumes you've already installed Termux:API add-on app
termux-keystore list | jq -r '.[].alias' | fgrep -q 'default' || \
	termux-keystore generate 'default' -a RSA -s 4096 -u 10

# setup internal and external storage symlinks
yes y | termux-setup-storage

# prevent termux from sourcing .bashrc twice every login
# note: termux sources .bashrc before .profile on all logins
sed -ni ~/.profile -e '/## login shell/q;p'

# ~/.bashrc
# changes to shell startup, entry point for termux
# force a normal-ish bash login shell
! fgrep -q '$TERMUX' < ~/.bashrc && {
	# simulate FHS standard locations w/o termux-chroot
	sed -i ~/.profile -E \
		-e 's,^(export XDG_RUNTIME_DIR).*,\1="$PREFIX/tmp",'

	# ssh-agent tweaks
	# android 11+ kills background daemons, run ssh-agent as parent process
	sed -i ~/.bashrc \
		-e '1s/^/[ ! -z "$TERMUX" ] || \\\n\t{ export TERMUX=1; exec ssh-agent -t 3600 bash -l; }\n/'

	# use fingerprint lock and android keystore instead of passphrase
	cat <<- EOF >> ~/.profile
		# $0: use fingerprint lock and android keystore with ssh-agent
		export SSH_ASKPASS='termux-ssh-askpass'
		export SSH_ASKPASS_REQUIRE='force'
	EOF

	# disable $OLDPWD persistence
	sed -i ~/.bashrc -e '/LASTDIR/d'

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
rm -f $PREFIX/etc/motd*

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
	# make full use of display in landscape mode
	# disable extra keys with VolUp+q
	#fullscreen=true

	enforce-char-based-input = false
	extra-keys-style = arrows-all
	extra-keys = [ \
		[ ESC, '~',  '/', HOME, UP,   END,   PGUP, DEL  ], \
		[ TAB, CTRL, ALT, LEFT, DOWN, RIGHT, PGDN, BKSP ] \
	]
EOF

# save changes to .patch file
# use 'patch -p1' to reapply without re-running script
git meta diff --color=never > "$CONF/diff.patch"
