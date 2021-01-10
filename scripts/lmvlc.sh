#!/bin/bash

PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
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
AUDIO_OUT=$(get_config_var audio $RCONFIGFILE)
INPUT_SEL=$(get_config_var input $RCONFIGFILE)
INPUT_SEL_T=$(get_config_var input1 $RCONFIGFILE)
LNBVOLTS=$(get_config_var lnbvolts $RCONFIGFILE)
DISPLAY=$(get_config_var display $PCONFIGFILE)

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

# Send audio to the correct port
if [ "$AUDIO_OUT" == "rpi" ]; then
  # Check for latest Buster update
  aplay -l | grep -q 'bcm2835 Headphones'
  if [ $? == 0 ]; then
    AUDIO_DEVICE="hw:CARD=Headphones,DEV=0"
  else
    AUDIO_DEVICE="hw:CARD=ALSA,DEV=0"
  fi
else
  AUDIO_DEVICE="hw:CARD=Device,DEV=0"
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

sudo killall longmynd >/dev/null 2>/dev/null
sudo killall vlc >/dev/null 2>/dev/null

sudo rm longmynd_main_ts >/dev/null 2>/dev/null
mkfifo longmynd_main_ts

sudo /home/pi/longmynd/longmynd -s longmynd_status_fifo -r -1 -g $GAIN_T -S $SCAN $VOLTS_CMD $INPUT_CMD $FREQ_KHZ $SYMBOLRATEK &

if [ "$DISPLAY" == "Element14_7" ]; then
  cvlc -I rc --rc-host 127.0.0.1:1111 -f --no-video-title-show \
    --width 800 --height 480 \
    --gain 3 --alsa-audio-device $AUDIO_DEVICE \
    longmynd_main_ts 2>/home/pi/tmp/vlclog.txt &
else  # Waveshare
  cvlc -I rc --rc-host 127.0.0.1:1111 -f --no-video-title-show \
    --gain 3 --alsa-audio-device $AUDIO_DEVICE \
    longmynd_main_ts 2>/home/pi/tmp/vlclog.txt &
fi

exit
