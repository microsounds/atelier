#!/usr/bin/env sh

# install waifu2x binary and models from github

SOURCE='https://github.com/nihui/waifu2x-ncnn-vulkan/releases/download/20220728'
ZIP='waifu2x-ncnn-vulkan-20220728-ubuntu.zip'
INSTALL="$HOME/.local"

wget -O - "$SOURCE/$ZIP" | busybox unzip - -d "$INSTALL"
mkdir -p "$INSTALL/share"
rm -rfv "$INSTALL/share/waifu2x"
mv -vf "$INSTALL/${ZIP%.*}" "$INSTALL/share/waifu2x"
chmod -v 755 "$INSTALL/share/waifu2x/waifu2x-ncnn-vulkan"
mv -v "$INSTALL/share/waifu2x/waifu2x-ncnn-vulkan" "$INSTALL/bin"
