#!/usr/bin/env sh

# git meta configuration automated setup
echo "$0"

# upstream
git meta remote add origin 'ssh://git@github.com/microsounds/atelier'
git meta push -u origin master

# set to ignore all untracked files in $HOME when calling git status
git meta config status.showUntrackedFiles no

