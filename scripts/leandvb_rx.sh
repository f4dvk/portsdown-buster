#! /bin/bash

# Amended 201802040 DGC

PATHBIN="/home/pi/rpidatv/bin/"
PATHSCRIPT="/home/pi/rpidatv/scripts"
CONFIGFILE=$PATHSCRIPT"/rpidatvconfig.txt"
#PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
RXPRESETSFILE="/home/pi/rpidatv/scripts/rx_presets.txt"

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

SYMBOLRATEK=$(get_config_var rx0sr $RXPRESETSFILE)
FREQ_OUTPUT=$(get_config_var rx0frequency $RXPRESETSFILE)
SDR=$(get_config_var rx0sdr $RXPRESETSFILE)
MODULATION=$(get_config_var rx0modulation $RXPRESETSFILE)
FEC=$(get_config_var rx0fec $RXPRESETSFILE)
let FECNUM=FEC
let FECDEN=FEC+1

FreqHz=$(echo "($FREQ_OUTPUT*1000000)/1" | bc )
let SYMBOLRATE=SYMBOLRATEK*1000

#let FreqHz=FREQ_OUTPUT*1000000
echo Freq = $FreqHz

if [ "$SYMBOLRATEK" -lt 251 ]; then
  SR_RTLSDR=300000
elif [ "$SYMBOLRATEK" -gt 250 ] && [ "$SYMBOLRATEK" -lt 1000 ]; then
  SR_RTLSDR=1200000
elif [ "$SYMBOLRATEK" -gt 999 ] && [ "$SYMBOLRATEK" -lt 1001 ]; then
  SR_RTLSDR=1500000
else
  SR_RTLSDR=2400000
fi
#SR_RTLSDR=1024000

if [ "$SDR" = "RTLSDR" ]; then
  KEY="sudo rtl_sdr -p 0 -g 0 -f $FreqHz -s $SR_RTLSDR - 2>/dev/null "
  B=""
fi
if [ "$SDR" = "LIMEMINI" ]; then
  KEY="sudo /home/pi/rpidatv/bin/limesdr_dump -f $FreqHz -b 5e6 -s $SR_RTLSDR -g 1 -l 256*256 |buffer"
  B="--s12"
fi

sudo killall -9 hello_video.bin
sudo killall leandvb
sudo killall ts2es
mkfifo fifo.264
mkfifo videots

# Make sure that the screen background is all black
sudo killall fbi >/dev/null 2>/dev/null
sudo fbi -T 1 -noverbose -a $PATHSCRIPT"/images/Blank_Black.png"
(sleep 1; sudo killall -9 fbi >/dev/null 2>/dev/null) &  ## kill fbi once it has done its work

#--fd-pp 3 
#sudo rtl_sdr -p 20 -g 30 -f $FreqHz -s $SR_RTLSDR - 2>/dev/null | $PATHBIN"leandvb"  --cr $FECNUM"/"$FECDEN --sr $SYMBOLRATE -f $SR_RTLSDR 2>/dev/null |buffer| $PATHBIN"ts2es" -video -stdin fifo.264 &
$KEY| $PATHBIN"leandvb" $B --fd-pp 3 --fd-info 2 --fd-const 2  --cr $FECNUM"/"$FECDEN --fastlock --sr $SYMBOLRATE -f $SR_RTLSDR  3>fifo.iq | $PATHBIN"ts2es" -video -stdin fifo.264 & 
#sudo rtl_sdr -p 20 -g 40 -f $FreqHz -s $SR_RTLSDR - 2>/dev/null | $PATHBIN"leandvb"  -- --gui -d --cr $FECNUM"/"$FECDEN --sr $SYMBOLRATE -f $SR_RTLSDR  |buffer| $PATHBIN"ts2es" -video -stdin fifo.264 &
#sudo rtl_sdr  -p 20 -g 30 -f 650000000 -s 1024000 - 2>/dev/null | $PATHBIN"leandvb"  --filter --gui -d --cr 7/8 --sr 250000 -f 1024000 | $PATHBIN"ts2es" -video -stdin fifo.264 &
#sudo rtl_sdr -p 20 -g 30 -f 650000000 -s 1024000 - 2>/dev/null | $PATHBIN"leandvb"  --filter --gui -d --cr 7/8 --sr 250000 -f 1024000 > file.ts
$PATHBIN"hello_video.bin" fifo.264 &


#sudo rtl_sdr -p 20 -g 40 -f 650040000 -s 1024000 - 2>/dev/null | ./leandvb_vt100ui.sh ./leandvb --fd-info 2 --fastlock --fd-const 2  --cr 7/8 --sr 249994 -f 1024000  > file.ts
#sudo rtl_sdr -p 20 -g 30 -f 650040000 -s 1024000 - 2>/dev/null | ./leandvb_tiounemonitor.sh ./leandvb --fd-info 2 --fd-const 2 --cr 7/8 --sr 250000 -f 1024000 > file.ts
#./leandvb_vt100ui.sh ./leandvb  -d --cr 7/8 --sr 250000 -f 1024000 --fd-info 2 --fd-const 2 < rtl_sdr -p 20 -g 30 -f 437000000 -s 1024000 - >file.ts
#sudo rtl_sdr -p 60 -g 40 -f 650000000 -s 1024000 test650MHZ_SR250_FS1024.iq
