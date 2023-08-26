#!/usr/bin/env sh

# defines standard apt repositories
# adds supplementary repos
# pulls in upgrades if needed

BRANCH='bookworm' # released 2023/06

CONF='/etc/apt/sources.list'
TRUSTED='/etc/apt/trusted.gpg.d'
APTCONF='/etc/apt/apt.conf.d/non-interactive'
TMP="$(mk-tempdir)"

finish() {
	rm -rv "$TMP"
	sudo rm -rv "$APTCONF"
	echo 'Done.'
	exit
}

trap finish 0 1 2 3 6 15

mkdir -v "$TMP"
mkdir -v "${CONF}.d"
echo "Writing to '$CONF'"
sudo tee "$CONF" <<- EOF
	deb https://deb.debian.org/debian $BRANCH main contrib non-free non-free-firmware
	deb-src https://deb.debian.org/debian $BRANCH main contrib non-free non-free-firmware
	deb https://deb.debian.org/debian $BRANCH-updates main contrib non-free non-free-firmware
	deb https://security.debian.org/debian-security $BRANCH-security main contrib non-free non-free-firmware
EOF

# deb-multimedia
SRC='https://www.deb-multimedia.org/pool/main/d/deb-multimedia-keyring'
KEY='deb-multimedia-keyring_2016.8.1_all.deb'

wget "$SRC/$KEY" -O "$TMP/$KEY" || exit 1
sudo dpkg -i "$TMP/$KEY"
sudo tee "${CONF}.d/deb-multimedia.list" <<- EOF
	deb https://www.deb-multimedia.org $BRANCH main non-free
EOF

# wine-hq
SRC='https://dl.winehq.org/wine-builds'
KEY='winehq.key'

wget "$SRC/$KEY" -O "$TMP/$KEY" || exit 1
sudo cp -v "$TMP/$KEY" "$TRUSTED/${KEY%.*}.asc"
sudo tee "${CONF}.d/wine-hq.list" <<- EOF
	deb https://dl.winehq.org/wine-builds/debian/ $BRANCH main
EOF
# add 32-bit architecture on amd64
uname -m | fgrep -q 'x86_64' && sudo dpkg --add-architecture i386

# temporarily disable all prompts
cat <<- EOF | sudo tee "$APTCONF"
	DPkg::options { "--force-confdef"; "--force-confnew"; }
EOF

# run shell function update() non-interactively
yes y | bash -lc 'update'
