#!/usr/bin/env sh
# git-submodule is ill-suited for installing suckless software
# git doesn't allow commits that contain pre-written .git/configs either

cd ~/.config/dwm
git init
git remote add origin 'https://git.suckless.org/dwm'
git pull origin master
sudo make install -j $(grep -c 'proc' /proc/cpuinfo)
