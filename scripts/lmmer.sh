#!/bin/bash

PATHBIN="/home/pi/rpidatv/bin/"
RCONFIGFILE="/home/pi/rpidatv/scripts/longmynd_config.txt"
PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"

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

# Set Beacon Freq and SR here:

FREQ_KHZ="10491500"
SYMBOLRATEK="1500"

# Read from receiver config file
Q_OFFSET=$(get_config_var qoffset $RCONFIGFILE)
UDPIP=$(get_config_var udpip $RCONFIGFILE)
UDPPORT=$(get_config_var udpport $RCONFIGFILE)
INPUT_SEL=$(get_config_var input $RCONFIGFILE)
DISPLAY=$(get_config_var display $PCONFIGFILE)
LNBVOLTS=$(get_config_var lnbvolts $RCONFIGFILE)

# Correct for LNB LO Frequency
let FREQ_KHZ=$FREQ_KHZ-$Q_OFFSET

# Select the correct tuner input
INPUT_CMD=" "
if [ "$INPUT_SEL" == "b" ]; then
  INPUT_CMD="-w"
fi

GAIN=$(get_config_var gain $RCONFIGFILE)
GAIN_T=$GAIN/2

SCAN=$(get_config_var scan $RCONFIGFILE)

# Set the LNB Volts
VOLTS_CMD=" "
if [ "$LNBVOLTS" == "h" ]; then
  VOLTS_CMD="-p h"
fi
if [ "$LNBVOLTS" == "v" ]; then
  VOLTS_CMD="-p v"
fi

sudo rm fifo.264

sudo rm longmynd_main_ts

if [ "$DISPLAY" != "Element14_7" ]; then # Select bleeps (which don't work with the Element 14 display)
  sudo /home/pi/longmynd/longmynd -b -i $UDPIP $UDPPORT -s longmynd_status_fifo -g $GAIN_T -S $SCAN $VOLTS_CMD $INPUT_CMD $FREQ_KHZ $SYMBOLRATEK &
else
  sudo /home/pi/longmynd/longmynd -i $UDPIP $UDPPORT -s longmynd_status_fifo -g $GAIN_T -S $SCAN $VOLTS_CMD $INPUT_CMD $FREQ_KHZ $SYMBOLRATEK &
fi

exit
