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
if [ "$MODULATION" = "DVB-S" ]; then
 let FECNUM=FEC
 let FECDEN=FEC+1
 FECDVB="--cr $FECNUM"/"$FECDEN"
else
 FECDVB=""
fi

FreqHz=$(echo "($FREQ_OUTPUT*1000000)/1" | bc )
let SYMBOLRATE=SYMBOLRATEK*1000

#let FreqHz=FREQ_OUTPUT*1000000
echo Freq = $FreqHz

  if [ "$FREQ_OUTPUT" = "145.9" ] && [ "$SDR" = "LIMEMINI" ]; then
    GAIN=1
  elif [ "$FREQ_OUTPUT" = "437" ] && [ "$SDR" = "LIMEMINI" ]; then
    GAIN=0.5
  elif [ "$FREQ_OUTPUT" = "1255" ] && [ "$SDR" = "LIMEMINI" ]; then
    GAIN=1
  fi

  if [ "$SYMBOLRATEK" -lt 251 ]; then
    SR_RTLSDR=300000
  elif [ "$SYMBOLRATEK" -gt 250 ] && [ "$SYMBOLRATEK" -lt 500 ] && [ "$SDR" = "RTLSDR" ]; then
    SR_RTLSDR=1000000
  elif [ "$SYMBOLRATEK" -gt 499 ] && [ "$SYMBOLRATEK" -lt 1000 ]; then
    SR_RTLSDR=1200000
  elif [ "$SYMBOLRATEK" -gt 999 ] && [ "$SYMBOLRATEK" -lt 1101 ]; then
    SR_RTLSDR=1250000
  elif [ "$SYMBOLRATEK" -gt 250 ] && [ "$SYMBOLRATEK" -lt 500 ] && [ "$SDR" = "LIMEMINI" ]; then
    SR_RTLSDR=850000
  else
    SR_RTLSDR=2400000
  fi
#SR_RTLSDR=1024000

if [ "$SDR" = "RTLSDR" ]; then
  KEY="sudo rtl_sdr -p 0 -g 0 -f $FreqHz -s $SR_RTLSDR - 2>/dev/null "
  B=""
fi
if [ "$SDR" = "LIMEMINI" ]; then
  KEY="sudo /home/pi/rpidatv/bin/limesdr_dump -f $FreqHz -b 5e6 -s $SR_RTLSDR -g $GAIN -l 512*512 |buffer"
  B="--s12"
fi

if [ "$MODULATION" != "DVB-S" ] && [ "$MODULATION" != "DVB-S2" ]; then
 if [ "$MODULATION" = "8PSK" ]; then
  MODULATION="DVB-S2"
  CONST="8PSK"
 elif [ "$MODULATION" = "16APSK" ]; then
  MODULATION="DVB-S2"
  CONST="16APSK"
 elif [ "$MODULATION" = "32APSK" ]; then
  MODULATION="DVB-S2"
  CONST="32APSK"
 fi
else
 CONST="QPSK"
fi

sudo rm fifo.264 >/dev/null 2>/dev/null
sudo rm videots >/dev/null 2>/dev/null
sudo killall -9 hello_video.bin >/dev/null 2>/dev/null
sudo killall -9 hello_video2.bin >/dev/null 2>/dev/null
sudo killall leandvb >/dev/null 2>/dev/null
sudo killall ts2es >/dev/null 2>/dev/null
mkfifo fifo.264
mkfifo videots

# Make sure that the screen background is all black
sudo killall fbi >/dev/null 2>/dev/null
sudo fbi -T 1 -noverbose -a $PATHSCRIPT"/images/Blank_Black.png"
(sleep 1; sudo killall -9 fbi >/dev/null 2>/dev/null) &  ## kill fbi once it has done its work

#--fd-pp 3
#sudo rtl_sdr -p 20 -g 30 -f $FreqHz -s $SR_RTLSDR - 2>/dev/null | $PATHBIN"leandvb"  --cr $FECNUM"/"$FECDEN --sr $SYMBOLRATE -f $SR_RTLSDR 2>/dev/null |buffer| $PATHBIN"ts2es" -video -stdin fifo.264 &
$KEY| $PATHBIN"leandvb" $B --fd-pp 3 --fd-info 2 --fd-const 2  $FECDVB --fastlock --sr $SYMBOLRATE --standard $MODULATION --const $CONST -f $SR_RTLSDR  3>fifo.iq | $PATHBIN"ts2es" -video -stdin fifo.264 &
#sudo rtl_sdr -p 20 -g 40 -f $FreqHz -s $SR_RTLSDR - 2>/dev/null | $PATHBIN"leandvb"  -- --gui -d --cr $FECNUM"/"$FECDEN --sr $SYMBOLRATE -f $SR_RTLSDR  |buffer| $PATHBIN"ts2es" -video -stdin fifo.264 &
#sudo rtl_sdr  -p 20 -g 30 -f 650000000 -s 1024000 - 2>/dev/null | $PATHBIN"leandvb"  --filter --gui -d --cr 7/8 --sr 250000 -f 1024000 | $PATHBIN"ts2es" -video -stdin fifo.264 &
#sudo rtl_sdr -p 20 -g 30 -f 650000000 -s 1024000 - 2>/dev/null | $PATHBIN"leandvb"  --filter --gui -d --cr 7/8 --sr 250000 -f 1024000 > file.ts
$PATHBIN"hello_video.bin" fifo.264 &


#sudo rtl_sdr -p 20 -g 40 -f 650040000 -s 1024000 - 2>/dev/null | ./leandvb_vt100ui.sh ./leandvb --fd-info 2 --fastlock --fd-const 2  --cr 7/8 --sr 249994 -f 1024000  > file.ts
#sudo rtl_sdr -p 20 -g 30 -f 650040000 -s 1024000 - 2>/dev/null | ./leandvb_tiounemonitor.sh ./leandvb --fd-info 2 --fd-const 2 --cr 7/8 --sr 250000 -f 1024000 > file.ts
#./leandvb_vt100ui.sh ./leandvb  -d --cr 7/8 --sr 250000 -f 1024000 --fd-info 2 --fd-const 2 < rtl_sdr -p 20 -g 30 -f 437000000 -s 1024000 - >file.ts
#sudo rtl_sdr -p 60 -g 40 -f 650000000 -s 1024000 test650MHZ_SR250_FS1024.iq
