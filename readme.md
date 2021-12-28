<!-- header and github badges -->
# <div align="center">_dotfiles—"atelier"_![shimeji]</div>
<div align="center">
	<img src="https://img.shields.io/github/commit-activity/m/microsounds/atelier?logo=github">
	<img src="https://img.shields.io/github/repo-size/microsounds/atelier?logo=github">
	<a href="https://github.com/microsounds/atelier/actions/workflows/ci.yml"><img src="https://github.com/microsounds/atelier/actions/workflows/ci.yml/badge.svg"></a>
	<br>
	<a href="https://debian.org/distrib/"><img src="https://img.shields.io/badge/Debian-bullseye-%23c70036.svg?logo=debian"></a>
	<a href="https://dwm.suckless.org/"><img src="https://img.shields.io/badge/suckless-dwm-%23224488?logo=suckless"></a>
	<a href="https://nano-editor.org/"><img src="https://shields.io/badge/Editor-GNU%20nano-%23440077?logo=windows-terminal"></a>
	<a href="https://www.youtube.com/watch?v=UL8IpdFGeHU"><img src="https://img.shields.io/badge/theme-night drive-%2363B0B0?logo=github-sponsors"></a>
	<br>
	<a href="http://canarypop.ciao.jp/shimehatsune.htm"><sup><i>shimeji miku &copy; 2010 canary yellow</i></sup></a>
</div>

This is my primary computing setup, a self-contained graphical shell environment for Debian GNU/Linux.
* Git is used to maintain an identical and reproducible setup across multiple machines.
* A series of post-install scripts in [`~/.once.d`](.once.d) document and reproduce system-wide deviations from a fresh install.
	* _A [suite of unit tests](.github/workflows/ci.yml) ensures a reproducible installation with each revision._

Basic installation instructions are provided, along with some documentation for the most essential components.

<!-- figure 1: desktop screenshot -->
[![scrot]][scrot]
_Pictured: Debian stable, a "graphical shell" environment consisting mostly of xorg, dwm, sxhkd and various urxvt clients._

# Quick start
1. Install Debian stable, perform a base install with no DE selected and no standard utilities when prompted.
	* _Do not perform these steps on `tty1`, `xinit` will launch without `dwm` present and you will be kicked._
2. Install `git`, `wget`, and `sudo`, then add yourself to the `sudo` group.
	* Log back in to apply changes to group membership.
3. Bootstrap the system automatically with a hard git reset from this repo, this is done only once.
	```shell
	$ git clone --bare {GIT_REMOTE}/atelier ~/.config/meta
	$ git --git-dir=$HOME/.config/meta --work-tree=$HOME reset --hard
	# Invoke the login shell to apply changes made to the environment
	$ exec $SHELL -l
	```
4. Run `post-install` in the shell to run post-install scripts automatically.
	* _Sets up the package manager, installs essential packages, compiles window manager, text editor, etc._
5. Reboot to finish.
	* _[`xinit`](.xinitrc) starts automatically upon login to [`tty1`](.profile)._

<!-- figure 2: mobile screenshot -->
<a href="https://raw.githubusercontent.com/microsounds/microsounds/master/dotfiles/mobile-scrot.jpg">
	<img width="125px" align="right" src="https://raw.githubusercontent.com/microsounds/microsounds/master/dotfiles/mobile-scrot2.png">
</a>

## Quick start on Termux for Android
> **NOTE**<br>
> _Currently, only a basic shell environment in single-user mode is supported.<br>
> This is meant to be a lightweight port with modifications, do not initiate a full `post-install`._

1. Install `git`, and bootstrap the system using `git reset --hard` as described above.
2. Post-install: Run only [`~/.once.d/a0-android-termux.sh`](.once.d/a0-android-termux.sh)
	* Applies android-specific hacks and termux specific dotfiles for theming and softkeys.
3. When pulling changes from upstream, always stash changes to prevent merge conflicts.

## Notes on platform support
**Full graphical shell environment**
* Any conventional BIOS/UEFI-compliant x86-based Personal Computer
* x86-based Chromebooks in Developer Mode (SeaBIOS), or liberated with UEFI firmware (Coreboot).
	* _See <https://mrchromebox.tech/> for more information on unlocking your bootloader._
* [Next Thing Co. PocketC.H.I.P][ntc-chip] armhf-based portable ~~toy computer~~ linux handheld
	* _Final NTC-provided Debian 8 (jessie) OS images from 2016 come with out-of-tree `4.4.13-ntc-mlc` kernel pinned, upgradeable to 10 (buster)._

[ntc-chip]: http://chip.jfpossibilities.com/docs/pocketchip.html "Mirrored PocketCHIP documentation"

**Single-user minimal shell environment**
* Bootstrapping in virtualized container instances for use in CI/CD workflows
* Termux terminal emulator and Linux environment for Android
	* _Non-standard *NIX environment, currently only supports a subset of available features._

# Usage notes
## Using `git meta`
For local-scope changes, files in `$HOME` are versioned and mangled in place using Git.
* `$HOME` is considered the detached working tree for a git **bare repo** located at `~/.config/meta`
* The `meta` alias prefixes all git commands with `--git-dir=$HOME/.config/meta --work-tree=$HOME`
* `meta status` will ignore files not manually added or tracked by this git repo.
	* _This is achieved using the `status.showUntrackedFiles` option and not via manually updating `~/.gitignore` as is commonly done._
* Invoking `git` outside of a valid git directory will append the `meta` alias automatically.
	* _`init` and `clone` commands are unaffected._

## Using `~/.once.d` post-install scripts
All system-wide changes are performed through automated scripts located in [`~/.once.d`](.once.d), you can run them all at once with shell function `post-install`.
Each script is self-contained, you can run them individually, anytime.

* Some scripts only apply to specific hardware configurations, and will exit even if they are run.
* Scripts affecting `systemd` or the bootloader will be skipped in virtualized container contexts.
* Locally installed software is installed to [`~/.local/bin`](.local/bin) when possible.

| series | function |
| -- | -- |
| `0*` | System-wide changes performed through the package manager. |
| `1*` | Changes to [`~/.local`](.local) file hierarchy, such as locally installed software and resources. |
| `2*` | System-wide changes that bypass the package manager, such as changes to `/etc`.<br>_These are hacks._ |
| `c*` | System-wide changes affecting chromebook hardware only. |
| `a*` | Android-specific hacks only. |
| `p*` | NTC PocketCHIP-specific hacks only. |

### Essential and *optional package groups
* [ `~/.comforts` ](.comforts) describes a list of non-optional package groups that will be installed through the package manager.
	* _Optional package groups are marked with an *asterisk, you will be prompted to approve these at runtime._

### Essential and *persistent upstream utilities
* [`~/.comforts-git`](.comforts-git) describes the full list of utilities compiled and installed from their upstream git sources.
	* _Repos must have a typical `./configure` and/or `make install PREFIX=...` metaphor to build correctly._
	* _Sources marked with an *asterisk will be persistently installed to `~/.config/${URL##*/}`_

Installation can be customized with user-provided executable install ~~hacks~~ scripts, named `{pre,post}-run`.
These can be placed in [`~/.config/upstream`](.config/upstream) or at the root of a persistently installed utility's install directory as described above

Rationale for doing things this way is summarized in commit [`2fe1c3745`][rat].

[rat]: https://github.com/microsounds/atelier/commit/2fe1c3745 "introduced ~/.once.d/10-git-upstream.sh"

## Window manager
`dwm` keybinds are the [defaults][dwm] with several exceptions.
Primary modkey `Mod1` is super instead of alt.

[dwm]: https://ratfactor.com/dwm "suckless dwm tutorial"

| shift + | alt + | key |
| --: | --: | :-- |
| | kill window | F4 |
| counter-clockwise | switch focused window | tab |
| **shift +** | **super +** | **key** |
| float window<sup>[toggle]</sup> | monocle window<sup>[toggle]</sup> | space |
| set as master window<sup>[toggle]</sup> | terminal | return |
| | launcher | p |
| | file manager | e |
| | ssh-add<sup>[toggle]</sup> | backspace |
| partial screenshot | screenshot | print |
| | _reserved_ | scroll lock |
| | _reserved_ | pause |
| reboot | shutdown | F1 |
| hibernate | sleep | F2 |
| hibernate + reboot | display off | F3 |
| configure networking | calculator | F4 |
| configure displays | switch active display<sup>[toggle]</sup> | F5 |
| minimum brightness | lower brightness 10% | F6 |
| maximum brightness | raise brightness 10% | F7 |
| configure audio | mute<sup>[toggle]</sup> | F8 |
| | lower volume 5% | F9 |
| | raise volume 5% | F10 |
| | randomize wallpaper | F11 |
| | _reserved_ | F12 |
| | **ctrl + alt +** | **key**<sup>[special]</sup> |
| | task manager | delete |
| | syslog | insert |

### Reduced layout for Chromebooks
Search/Everything/Caps lock key serves as the super key. Same as above, with the following changes:

| alt gr + | key | remarks |
| --: | :-- | :-- |
| prior | up | |
| next | down | |
| home | left | |
| end | right | |
| delete | backspace | |
| F11 | delete | same as power key, keystroke repeat not available |

# Some environment notes
## X server invocation
No display manager is used, login to `tty1` to start the graphical shell.

All daemons and services required to support the graphical shell are initialized along with the X server and are terminated when the user terminates the session.

`systemd` unit services, cronjobs and similar mechanisms are avoided.

At startup, `startx` will pass hardware-specific `xorg.conf` files to the X server, to enable hardware compositing on supported hardware and eliminate screen tearing.

Xorg's security model forbids non-root users from passing arbitrary config files to the X server unless they are located in one of several "blessed" directories.
Post-install scripts will create symlink `/etc/X11/$(id -u)-override` that points to `~/.config/xorg` to override this behavior.

## Optional X Window configuration
### `~/.xrandr`
For use with multi-monitor and/or complicated display setups, you can override the default display layout with one or more commands to `xrandr` saved to _optional_ config file `~/.xrandr`

	# e.g. two monitors, right is mounted vertically
	--output HDMI-0 --auto --primary --rotate normal
	--output HDMI-1 --auto --right-of HDMI-0 --rotate right

Commands in this file are passed to [`xrandr-cycle`](Scripts/xrandr_cycle.sh) line by line at startup if it exists.
For example, this configuration would suit a 2 monitor layout with the right monitor mounted vertically.

### `~/.xdecor`
You can designate one or more paths to directories containing images or videos for use as a wallpaper using _optional_ config file `~/.xdecor`

	# prefixing with ~/ is acceptable
	~/Pictures/some/path
	/media/sd_card/some/path

If it exists, [`xwin-decor`](Scripts/xwin_decor.sh) will randomly pick a directory and file within it and set it as the wallpaper on startup.
In the case of video files, a random video frame from that file will be taken and set as the wallpaper using `ffmpeg`.

## X resources and theming
For consistency, `xinit`, `dwm` and other scripts make use of the C preprocessor to mangle config files and configure color schemes.

Theme settings and individual color schemes are stored as C header files containing preprocessor macros representing color hex codes in [`~/.local/include`](.local/include).
This directory is appended to `$C_INCLUDE_PATH` at login.

* Using shell function `reload` will reload changes to `.xresources` and hard-reset your current terminal instance.
* Use command `palette` to soft-reset color scheme using OSC terminal escapes without losing the current shell.

_Optionally, you can apply another existing color scheme by naming it as an argument.
This can be useful when dealing with TUI applications that force their own background colors._

### List of available macros
* `{FG,BG}COLOR` for terminal fg/bg colors
* `{FG,BG}LIGHT` for UX highlight colors
* `COLOR0..COLOR15` for the 16 standard ANSI terminal colors
* `FN_{TERM,HEADER,TEXT}` for specific font faces
* `FN_{TERM,HEADER}_JP` for matching fallback fonts
* `FN_{TERM,HEADER,TEXT}_SIZE` for matching font sizes
* `FN_EMOJI` for specifying fallback emoji glyphs
* `FN_EMOJI_SIZE` for specifying fallback emoji glyph sizes

## Issues with HiDPI scaling
HiDPI display setups are currently **not** supported, 96dpi is assumed everywhere.

HiDPI scaling brings up innumerable display issues in [every category of graphical software][dpi1]
including [electron-based applications][dpi2] that require polluting scripts and dotfiles to smooth out toolkit scaling issues.
Maintaining mixed-DPI multi-monitor setups in X11 is [even more painful][dpi3].

Or to put it another way, crisp terminal fonts are not worth peppering my scripts with toolkit-specific global variables and conditional logic just for HiDPI scaling.
See [`~/.local/include/theme.h`](.local/include/theme.h) for more info.

[dpi1]: https://wiki.archlinux.org/title/HiDPI "A laundry list of hacks to have consistent-looking fonts everywhere under HiDPI"
[dpi2]: https://blog.yossarian.net/2020/12/24/A-few-HiDPI-tricks-for-Linux "The real HiDPI experience on GNU/Linux"
[dpi3]: http://wok.oblomov.eu/tecnologia/mixed-dpi-x11/#mixeddpiinx11 "Workarounds for mixed DPI multi-monitor setups in X11"

# Non-standard commands
Several commands are extended to include impure functions, such as purposefully mangling config files, and have the following precedence when multiple versions exist:

1. Interactive shell functions defined in [`~/.bashrc`](.bashrc)
2. Non-interactive shell library executables in [`~/.local/lib`](.local/lib)
	* Shell script snippets used by multiple scripts to reduce clutter.
3. Normal executables and symlinks in [`~/.local/bin`](.local/bin)
	* Some are shell functions promoted to scripts so they'll work in `dmenu` or outside of a terminal context.
4. `/usr/bin` system-wide executables

## `cd`
* The contents of `$OLDPWD` is preserved between sessions.
* `cd` offers the following extensions:

	| opt | function |
	| -- | -- |
	| `...`, `....`, etc. | Shorthand for `../../`, `../../../` and so on. |
	| `-e <dirname>` | Fuzzy find and jump into a sub-directory. |

## `chromium`
> **NOTE**<br>
>_On first-run, `chromium` will momentarily exit and restart to rebuild configuration and enable use of externally customized color options._

`chromium` was extended to mangle the user-hostile per-profile `Preferences` and global `Local State` JSON files with a series of chained `jq` filters stored in the following files, applying persistent settings in order.
* [`~/.config/chromium/preferences.conf`](.config/chromium/preferences.conf)
* [`~/.config/chromium/local_state.conf`](.config/chromium/local_state.conf)

C preprocessor syntax is also accepted, hex color values in the form `#RRGGBB` will be converted to a signed integer representing `0xBBGGRRAA` in two's complement hexadecimal with `AA` (alpha channel) always set to `0xFF`

### Managed policy overrides
`chromium` is managed by `/etc/chromium/policies/managed/extensions.json`, set up during [post-install](.once.d/29-chromium-extensions.sh), which automatically installs several useful extensions on first-run, including [uBlock Origin][].

[uBlock Origin]: https://ublockorigin.com "uBlock Origin homepage"

## `git`
`git` aliases are defined in [`~/.gitconfig`](.gitconfig) or implemented in interactive shell function `git()`

See *Usage Notes* for more information.

* _This is a critical component of the graphic shell environment, some aliases are cumulative in nature._

	| alias | function |
	| -- | -- |
	| `meta` | Appends `--git-dir=$HOME/.config/meta --work-tree=$HOME` to a `git` command.<br>_(Added implicitly when outside a git directory.)_ |
	| `summary` | Outlines the last 20 commits with a commit graph. |
	| `list-files` | List all tracked filenames in repo, ideally for use with `xargs`. |
	| `flatten` | Automatically melds `--fixup/squash` commits out of existence starting from the root commit. |
	| `checkin` | Commit all changes immediately with a generic timestamp and hostname commit message. |
	| `shove` | Runs `checkin` and pushes immediately. |
	| `sync` | Runs `git meta pull` and then recurses through `~/Git` and runs `git pull` on every existing `git` repo found. |

## `nano`
> **NOTE**<br>
> _`nano` keybind macros make use of inline non-printable control characters, you must use `nano` or `cat -v` to view [`~/.nanorc`](.nanorc) correctly._

* `nano` is an alias for [`nano-overlay`](Scripts/nano_overlay.sh) which mangles config files and offers the following extended options:

	| opt | function |
	| -- | -- |
	| `-e, --ctags <tag> <#>`  | Jumps into file containing `ctags` definition matching `<tag>`.<br>Optional `<#>` selects from multiple matches, `all` will open all of them. |
	| `-c, --ctags-dict <file1>...` | Enable project-wide autocomplete by appending condensed dictionary of all `ctags` keywords to all files.<br>Dictionary will be removed upon exiting. |
	| `-f, --encrypt <file>` | Open AES encrypted text file with a plaintext password. <br>File will be created if it doesn't exist. |
	| `-j, --rsa <file>` | Open AES encrypted text file with generic RSA keypair in PEM format. <br>File will be created if it doesn't exist. |
	| `-s, --ssh-sign <file>` | Open AES encrypted text file with a nonce value signed with SSH private key. <br>File will be created if it doesn't exist. |
	| `-i, --identity <key>` | Use an OpenSSL compatible keypair to encrypt/decrypt. <br>Can be a private key or a public key with private half stored in `ssh-agent` |

* Once inside the actual `nano`, the following keybind macros are available:

	| key | function |
	| -- | -- |
	| `M-0` | Execute current line as shell command and pipe contents of buffer as stdin.<br>_Destructively replaces entire contents of buffer, useful for formatting._ |
	| `M-1` | Execute current line as shell command and paste output in current buffer.<br>_Inline comments ok._ |
	| `M-2` | Select token underneath cursor and jump into it's `ctags` definition(s) within the same shell.<br>_Requires valid `tags` file in current or a parent directory._ |
	| `M-4` | Select token underneath cursor and jump into it's `ctags` definition(s) in a new terminal window.<br>_Requires valid `tags` file in current or a parent directory._ |

## `notify-send`
This particular [`notify-send`](.local/lib/notify-send) implements only `-t` for expiration time in seconds,
because it doesn't tie into any `dbus`-based notification daemon implementing the [Desktop Notifications spec][notify].

[notify]: https://www.galago-project.org/specs/notification/0.9/index.html "freedesktop.org Desktop Notifications spec"

Instead, it's just a shell script that writes to a named pipe that gets picked up by [`xwin-statusd`](Scripts/wm_status.sh) as a simple way to implement OSD text and single-line notifications.

Unlike other implementations, you can pass notifications/OSD text as an argument or via stdin without using `xargs`.

## `sc` (spreadsheet calculator)
`sc` is supports macros to some degree, but it's macro implementation is [difficult to understand][sc_macros] and there aren't many examples of it being used successfully anywhere that I've managed to find.

[sc_macros]: https://github.com/n-t-roff/sc/blob/master/SC.MACROS "I'm not even sure this was implemented as written."

Instead, the shell function `sc()` offers an easier to understand macro system for statically mangling `.sc` spreadsheet files at runtime.
* `sc` will automatically run any executable sharing the same initial name as the `.sc` file.
	* _eg. `sheet1.sc` will run `sheet1.sc.1`, `sheet1.scx`, etc. if they exist in the same directory and are executable at runtime._
* You can write an arbitrarily complex pre-run macro script in any language, so long as it is made aware of it's own filename at runtime.
	* _Because the `sc` file format is plaintext, you can generate `sc` syntax with just a shell script._

### `sc` pre-run macro example
* This is an example of a conditional macro script for an inventory spreadsheet that color-codes cells when specific strings are found.

	```shell
	#!/usr/bin/env sh
	# apply colors to specific strings in column B

	file="${0%.*}" # derive .sc file name from name of this script

	# remove all instances of color from the file in place
	{ rm "$file"; egrep -v '^color' > "$file"; } < "$file"

	cat <<- EOF >> "$file" # set some non-default colors
		color 3 = @black;@red
		color 4 = @black;@yellow
		color 5 = @black;@green
	EOF
	# select only string cells from column B, apply colors based on string contents
	# sc format: leftstring B2 = "example string"
	egrep '^((left|right)string|label)' < "$file" | while read -r cmd cell _ str; do
		case "$cell" in B*)
			case "$str" in
				*broken*) echo "color $cell:$cell 3";;
				*bad*) echo "color $cell:$cell 4";;
				*working*) echo "color $cell:$cell 5";;
			esac;;
		esac
	done >> "$file"
	```

[scrot]: https://raw.githubusercontent.com/microsounds/microsounds/master/dotfiles/scrot.png
[shimeji]: https://raw.githubusercontent.com/microsounds/microsounds/master/dotfiles/shimeji.png
