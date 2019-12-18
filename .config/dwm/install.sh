#!/usr/bin/env sh
# git-submodule is ill suited for installing suckless programs
# git doesn't allow commits that contain pre-written .git/configs either

cd ~/.config/dwm
git init
echo '[remote "origin"]\n\turl = https://git.suckless.org/dwm' >> .git/config
git pull
sudo make install -j $(grep -c 'proc' /proc/cpuinfo)
