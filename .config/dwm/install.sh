#!/usr/bin/env sh
# git-submodule is ill-suited for installing suckless software
# git doesn't allow commits that contain pre-written .git/configs either

VER='6.2'

cd ~/.config/dwm
git init
git remote add origin 'https://git.suckless.org/dwm'
git fetch --tags origin master
git checkout "$VER"
sudo make install -j $(grep -c 'proc' /proc/cpuinfo)
