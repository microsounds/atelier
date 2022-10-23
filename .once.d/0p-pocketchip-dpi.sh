#!/usr/bin/env sh

# dumb hack that brings in screen font/DPI fixes for ntc pocketchip
# required by dwm/dmenu compilation in the next step

! is-ntc-chip && exit 0

patch -d $HOME -Np1 < ~/.once.d/ntc-chip.patch
