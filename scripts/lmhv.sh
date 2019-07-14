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

# Correct for LNB LO Frequency if required
if [ "$RX_MODE" == "sat" ]; then
  let FREQ_KHZ=$FREQ_KHZ-$Q_OFFSET
fi

sudo killall hello_video.bin

sudo killall longmynd


sudo rm fifo.264
mkfifo fifo.264

sudo /home/pi/longmynd/longmynd $FREQ_KHZ 0 $SYMBOLRATEK 0 &

$PATHBIN"ts2es" -video longmynd_ts_fifo fifo.264 &

$PATHBIN"hello_video.bin" fifo.264 &


exit
