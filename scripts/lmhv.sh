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
SYMBOLRATEK_T=$(get_config_var sr1 $RCONFIGFILE)
FREQ_KHZ=$(get_config_var freq0 $RCONFIGFILE)
FREQ_KHZ_T=$(get_config_var freq1 $RCONFIGFILE)
RX_MODE=$(get_config_var mode $RCONFIGFILE)
Q_OFFSET=$(get_config_var qoffset $RCONFIGFILE)
INPUT_SEL=$(get_config_var input $RCONFIGFILE)
INPUT_SEL_T=$(get_config_var input1 $RCONFIGFILE)
LNBVOLTS=$(get_config_var lnbvolts $RCONFIGFILE)

# Correct for LNB LO Frequency if required
if [ "$RX_MODE" == "sat" ]; then
  let FREQ_KHZ=$FREQ_KHZ-$Q_OFFSET
  SCAN=$(get_config_var scan $RCONFIGFILE)
else
  FREQ_KHZ=$FREQ_KHZ_T
  SYMBOLRATEK=$SYMBOLRATEK_T
  INPUT_SEL=$INPUT_SEL_T
  SCAN=$(get_config_var scan1 $RCONFIGFILE)
fi


# Select the correct tuner input
INPUT_CMD=" "
if [ "$INPUT_SEL" == "b" ]; then
  INPUT_CMD="-w"
fi

# Set the LNB Volts
VOLTS_CMD=" "
if [ "$LNBVOLTS" == "h" ]; then
  VOLTS_CMD="-p h"
fi
if [ "$LNBVOLTS" == "v" ]; then
  VOLTS_CMD="-p v"
fi

GAIN=$(get_config_var gain $RCONFIGFILE)
GAIN_T=$GAIN/2

sudo killall hello_video.bin
sudo killall ts2es
sudo killall longmynd
sudo killall nc

sudo rm fifo.264
mkfifo fifo.264

sudo rm longmynd_main_ts
mkfifo longmynd_main_ts

sudo /home/pi/longmynd/longmynd -s longmynd_status_fifo -g $GAIN_T -S $SCAN $VOLTS_CMD $INPUT_CMD $FREQ_KHZ $SYMBOLRATEK &

sleep 1  # Required for good start every time

$PATHBIN"ts2es" -video longmynd_main_ts fifo.264 &

$PATHBIN"hello_video.bin" fifo.264 &


exit
