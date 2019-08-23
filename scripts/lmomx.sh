#!/bin/bash

PATHBIN="/home/pi/rpidatv/bin/"
RCONFIGFILE="/home/pi/rpidatv/scripts/longmynd_config.txt"

############ FUNCTION TO READ CONFIG FILE #############################

get_config_var() {
lua - "$1" "$2" <<EOF
local key=assert(arg[1])
local fn=assert(arg[2])
local file=assert(io.open(fn))
for line in file:lines() do
local val = line:match("^#?%s*"..key.."=(.*)$")
if (val ~= nil) then
print(val)
break
end
end
EOF
}

cd /home/pi

# Read from receiver config file
SYMBOLRATEK=$(get_config_var sr0 $RCONFIGFILE)
FREQ_KHZ=$(get_config_var freq0 $RCONFIGFILE)
RX_MODE=$(get_config_var mode $RCONFIGFILE)
Q_OFFSET=$(get_config_var qoffset $RCONFIGFILE)
UDPIP=$(get_config_var udpip $RCONFIGFILE)
UDPPORT=$(get_config_var udpport $RCONFIGFILE)
AUDIO_OUT=$(get_config_var audio $RCONFIGFILE)

# Correct for LNB LO Frequency if required
if [ "$RX_MODE" == "sat" ]; then
  let FREQ_KHZ=$FREQ_KHZ-$Q_OFFSET
fi

if [ "$AUDIO_OUT" == "rpi" ]; then
  AUDIO_MODE="local"
else
  AUDIO_MODE="alsa:plughw:1,0"
fi


sudo killall longmynd >/dev/null 2>/dev/null
sudo killall omxplayer.bin >/dev/null 2>/dev/null

sudo rm fifo.264
mkfifo fifo.264

sudo /home/pi/longmynd/longmynd $FREQ_KHZ 0 $SYMBOLRATEK 0  &

omxplayer --adev $AUDIO_MODE --live --display 1 --layer 10 longmynd_ts_fifo &  ## works OK

exit

#  For USB Audio dongle output, use:
#omxplayer --adev alsa:plughw:1,0  --live --display 1 --layer 10 longmynd_ts_fifo &