#!/bin/bash

# Called by rpidatvtouch to start the player for IPTS and return stdout
# in a status file

stdbuf -oL omxplayer --video_queue 0.5 --timeout 5 udp://:@:10000 2>/dev/null | {
LINE="1"
rm  /home/pi/tmp/stream_status.txt >/dev/null 2>/dev/null
while IFS= read -r line
do
  # echo $line
  if [ "$LINE" = "1" ]; then
    echo "$line" >> /home/pi/tmp/stream_status.txt
    LINE="2"
  fi
done
# Exits loop when omxplayer is killed or a stream stops

rm  /home/pi/tmp/stream_status.txt >/dev/null 2>/dev/null
echo "$line" >> /home/pi/tmp/stream_status.txt
}
