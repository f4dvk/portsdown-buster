#!/bin/bash

# Set the look-up files
PATHBIN="/home/pi/rpidatv/bin/"
PATHSCRIPT="/home/pi/rpidatv/scripts"
CONFIGFILE=$PATHSCRIPT"/rpidatvconfig.txt"
PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
RXPRESETSFILE="/home/pi/rpidatv/scripts/rx_presets.txt"
RTLPRESETSFILE="/home/pi/rpidatv/scripts/rtl-fm_presets.txt"

# Define proc to look-up with
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

# Look up and calculate the Receive parameters
FREQ_RX_FM=$(get_config_var r0freq $RTLPRESETSFILE)
MODE_RX_FM=$(get_config_var r0mode $RTLPRESETSFILE)
SQUELCH_RX_FM=$(get_config_var r0squelch $RTLPRESETSFILE)
GAIN_RX_FM=$(get_config_var r0gain $RTLPRESETSFILE)
CARD="0"

if [ "$MODE_RX_FM" = "am" ] || [ "$MODE_RX_FM" = "fm" ]; then
  SAMPLE="12k"
  BW=",0 -f S16_LE -r12"
else
  SAMPLE=""
fi

if [ "$MODE_RX_FM" = "wbfm" ]; then
  BW=",0 -f S16_LE -r32"
fi

if [ "$MODE_RX_FM" = "usb" ] || [ "$MODE_RX_FM" = "lsb" ]; then
  BW=",0 -f S16_LE -r6"
fi


rtl_fm -f $FREQ_RX_FM"M" -M $MODE_RX_FM $SAMPLE -g $GAIN_RX_FM -l $SQUELCH_RX_FM -E pad | aplay -D plughw:$CARD$BW &
