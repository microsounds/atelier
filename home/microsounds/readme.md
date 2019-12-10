# ![miku] quick ![miku] start ![miku]
* Create a user with the correct name and install `git`
* `git clone --bare [remote] ~/Git/atelier`
	* _This is your local copy._
* `git --work-tree=/ --git-dir=Git/atelier checkout .gitconfig`
* `git root reset --hard` to restore configuration automatically.
* Initialize `~/.config/dwm`, pull from `https://git.suckless.org/dwm` and then `make install`
* Install everything listed and then `source .bashrc` to finish.

# Using the entire filesystem as a git work-tree
* `git root` is an alias for working with bare repo `~/Git/atelier` with the work-tree starting at `/`
	* Do _**NOT**_ track files that require root permissions unless you want to be root for every checkout and pull.

## Comforts
```
sudo htop git gcc make xorg wmctrl xclip xbacklight sxhkd acpi rxvt-unicode-256color
screenfetch feh ffmpeg mpv suckless-tools pulseaudio alsa-utils network-manager sshfs
```
## Fonts
```
fonts-liberation fonts-dejima-mincho # dwm
fonts-noto-mono fonts-vlgothic # terminal
```
## Libs
``` 
libx11-dev libxft-dev libxinerama-dev # dwm
libdbus-glib-1-2 libgtk-3-0 # firefox
```

[miku]: https://i.imgur.com/Nr7HV9a.png
