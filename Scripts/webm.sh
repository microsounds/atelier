#!/usr/bin/env bash

# webm.sh
# record screen, save in webm format

# quality
SIZE=3M
BITRATE=3M # 4M
SCALE=-1:-1 # 800:-1
FPS=60 # 25

# system
CORES=$(cat /proc/cpuinfo | grep -i "processor" | wc -l)
RES=$(xrandr | grep '*' | awk '{print $1}')
TEMP=$(mktemp -u --suffix=".mp4")
FINAL="Screenshot - $(date '+%m%d%Y') - $(date '+%r').webm"

ffmpeg -threads $CORES -framerate $FPS -video_size $RES -f x11grab -i :0.0+0,0 -vcodec libx264 -qp 0 -preset ultrafast "$TEMP"
ffmpeg -i "$TEMP" -c:v libvpx -b:v $BITRATE -fs $SIZE -vf scale=$SCALE -threads $CORES -an "$FINAL"
rm -v $TEMP && sync
echo "File created at: $(readlink -f "$FINAL")"
