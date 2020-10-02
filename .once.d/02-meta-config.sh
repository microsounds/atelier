#!/usr/bin/env sh

# git meta configuration automated setup
echo "$0"

# use ssh by default, fallback to https if ~/.ssh doesn't exist
prefix='ssh://git@'
[ ! -d ~/.ssh ] && prefix='https://'
upstream='github.com/microsounds/atelier'

# fetch upstream
git meta remote remove origin
git meta remote add origin "$prefix$upstream"
git meta fetch
git meta branch -u origin/master

# set to ignore all untracked files in $HOME when calling git status
git meta config status.showUntrackedFiles no
