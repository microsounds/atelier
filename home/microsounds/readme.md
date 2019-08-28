# ![miku]quick ![miku] start ![miku]
* Create a user with the correct name and install `git`.
* `git clone --bare [remote] ~/Git/atelier`
	* _This is your local copy._
* Make local clone from this repo and copy `.bash_aliases` to home directory.
* `source .bashrc`
* `git-root reset --hard` and log back in.

## On committing and restoring changes
* `git-root` is an alias for working with bare repo `~/Git/atelier` with the work-tree starting at `/`
	* `git-root status` -- Ignore unmonitored files with `-u no`
* All normal git commands _(diff, checkout, etc.)_ should work.
	* _Keep things simple and **DO NOT** stage files that require root file permissions._
	* Push changes back to remote on occasion.

## Current comforts
```
sudo htop git gcc make xorg wmctrl screenfetch fonts-noto-mono rxvt-unicode-256color
# tentative
dwm dmenu st tabbed pulseaudio alsa-utils network-manager
libx11-dev libxinerama-dev libxft-dev
```

[miku]: https://i.imgur.com/Nr7HV9a.png
