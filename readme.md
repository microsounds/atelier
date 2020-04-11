[scrot]: https://i.imgur.com/0peU7Ia.png
[miku]: https://i.imgur.com/Nr7HV9a.png
# ![miku] _a t e l i e r_ ![miku]
![scrot]
> _Setup: Debian stable, vanilla Xorg, dwm + dmenu + sxhkd, urxvt + POSIX shell scripts._

# Quick start
1. Perform a base installation of Debian stable.
2. Install `sudo`, add yourself to the `sudo` group and install `git`.
	* _Group membership changes apply upon next login._
3. Bootstrap the system automatically using Git. _This is needed only once._
	```shell
	git clone --bare [remote] ~/.config/meta
	git --git-dir=$HOME/.config/meta --work-tree=$HOME reset --hard
	git meta config status.showUntrackedFiles no # set to ignore untracked files
	```
4. `cat ~/.comforts | xargs apt-get install -y` to install essential packages.
5. Run scripts in `~/.once.d` to build and install `dwm`, among other things.
	* _`for f in ~/.once.d/*; do $f; done`_
6. Reboot to finish.
	* _`xinit` starts automatically upon login to `tty1`, you will be kicked if `dwm` isn't installed._

# Notes
## Using `git meta`
`git meta` points to a detached _**bare**_ repo in `~/.config/meta` which manages the `$HOME` directory, allowing for in-place backup and version control of dotfiles.

* Every effort is made to maintain a reproducible GNU/Linux system that can be synchronized between various machines.
* Use of local, user-specific dotfiles that don't touch system defaults are preferred.
	* _eg. dotfiles in `$HOME` supersede any defaults located in `/etc`, `/usr/share`, etc._

## System-wide Configuration
* System-wide changes that bypass the package manager are avoided when possible.
	* _Necessary system-wide changes are reproduced with `~/.once.d` scripts._
* See __[~/.comforts](.comforts)__ for the full list of essential packages.
