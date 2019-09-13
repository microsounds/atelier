# ![miku]quick ![miku] start ![miku]
* Create a user with the correct name and install `git`.
	* _Log into `tty2`, you may be kicked off `tty1` halfway through._
* `git clone --bare [remote] ~/Git/atelier`
	* _This is your local copy._
* `git --work-tree=/ --git-dir=Git/atelier checkout .gitconfig`
* `git root reset --hard`
* `source .bashrc`
* Initialize `~/.config/dwm`, pull from `https://git.suckless.org/dwm` and then `make install`.

## On committing and restoring changes
* `git root` is an alias for working with bare repo `~/Git/atelier` with the work-tree starting at `/`
	* `git root status` -- Ignore unmonitored files with `-uno`
	* `git root add -u` and push changes back to remote on occasion.
	* Don't track files that require root permissions unless you want to be root for every checkout and pull.

### Tools
```
sudo htop git gcc make xorg wmctrl acpi rxvt-unicode-256color screenfetch feh
ffmpeg mpv suckless-tools pulseaudio alsa-utils network-manager sshfs xclip
```
### Fonts
```
fonts-liberation fonts-dejima-mincho # dwm
fonts-noto-mono fonts-vlgothic # term
```
### Libs
``` 
libx11-dev libxft-dev libxinerama-dev # dwm
libdbus-glib-1-2 libgtk-3-0 # firefox
```

[miku]: https://i.imgur.com/Nr7HV9a.png
