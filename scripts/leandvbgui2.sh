#!/bin/bash

# Amended 201807090 DGC

# Set the look-up files
PATHBIN="/home/pi/rpidatv/bin/"
PATHSCRIPT="/home/pi/rpidatv/scripts"
CONFIGFILE=$PATHSCRIPT"/rpidatvconfig.txt"
PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
RXPRESETSFILE="/home/pi/rpidatv/scripts/rx_presets.txt"
RTLPRESETSFILE="/home/pi/rpidatv/scripts/rtl-fm_presets.txt"
ACKFILE="/home/pi/rpidatv/scripts/ack_remote.txt"

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

CLIENTIP=$(cat /var/log/auth.log | grep -a 'Accepted password'| sed -n '$p' | sed 's/^.*from/from/' | awk '{print $2}')
IP_DISTANT=$(get_config_var rpi_ip_distant $PCONFIGFILE)
PORT=5001
PORT_IQ=5002

# Look up and calculate the Receive parameters

SYMBOLRATEK=$(get_config_var rx0sr $RXPRESETSFILE)
let SYMBOLRATE=SYMBOLRATEK*1000

UPSAMPLE=$(get_config_var upsample $PCONFIGFILE)
MODE_OUTPUT=$(get_config_var modeoutput $PCONFIGFILE)
PIN_I=$(get_config_var gpio_i $PCONFIGFILE)
PIN_Q=$(get_config_var gpio_q $PCONFIGFILE)
RF_GAIN=$(get_config_var rfpower $PCONFIGFILE)

FREQ_TX=$(get_config_var freqoutput $PCONFIGFILE)
LIME_TX_GAIN=$(get_config_var limegain $PCONFIGFILE)

LIME_TX_GAINA=`echo - | awk '{print '$LIME_TX_GAIN' / 100}'`

if [ "$LIME_TX_GAIN" -lt 6 ]; then
  LIME_TX_GAINA=`echo - | awk '{print ( '$LIME_TX_GAIN' - 6 ) / 100}'`
fi

FREQ_OUTPUT=$(get_config_var rx0frequency $RXPRESETSFILE)
FreqHz=$(echo "($FREQ_OUTPUT*1000000)/1" | bc )
#echo Freq = $FreqHz

MODULATION=$(get_config_var rx0modulation $RXPRESETSFILE)
FEC=$(get_config_var rx0fec $RXPRESETSFILE)
# Will need additional lines here to handle DVB-S2 FECs
if [ "$FEC" != "Auto" ]; then
 let FECNUM=FEC
 let FECDEN=FEC+1
 FECDVB="--cr $FECNUM"/"$FECDEN"
 FECIQ="$FECNUM"/"$FECDEN"
else
 FECDVB=""
fi

SDR=$(get_config_var rx0sdr $RXPRESETSFILE)

SAMPLERATEK=$(get_config_var rx0samplerate $RXPRESETSFILE)
if [ "$SAMPLERATEK" = "0" ]; then
  if [ "$SYMBOLRATEK" -lt 250 ]; then
    SR_RTLSDR=300000
  elif [ "$SYMBOLRATEK" -gt 249 ] && [ "$SYMBOLRATEK" -lt 500 ] && [ "$SDR" = "RTLSDR" ]; then
    SR_RTLSDR=1000000
  elif [ "$SYMBOLRATEK" -gt 499 ] && [ "$SYMBOLRATEK" -lt 1000 ]; then
    SR_RTLSDR=1200000
  elif [ "$SYMBOLRATEK" -gt 999 ] && [ "$SYMBOLRATEK" -lt 1101 ]; then
    SR_RTLSDR=1250000
  elif [ "$SYMBOLRATEK" -gt 250 ] && [ "$SYMBOLRATEK" -lt 400 ] && [ "$SDR" = "LIMEMINI" ]; then
    SR_RTLSDR=850000
  elif [ "$SYMBOLRATEK" == 250 ] && [ "$SDR" = "LIMEMINI" ]; then
    SR_RTLSDR=550000
  else
    SR_RTLSDR=2400000
  fi
else
  let SR_RTLSDR=SAMPLERATEK*1000
fi

#############################################

ETAT=$(get_config_var etat $RXPRESETSFILE)

#############################################

GAIN=$(get_config_var rx0gain $RXPRESETSFILE)

ENCODING=$(get_config_var rx0encoding $RXPRESETSFILE)

#SDR=$(get_config_var rx0sdr $RXPRESETSFILE)

GRAPHICS=$(get_config_var rx0graphics $RXPRESETSFILE)

PARAMS=$(get_config_var rx0parameters $RXPRESETSFILE)

SOUND=$(get_config_var rx0sound $RXPRESETSFILE)

FLOCK=$(get_config_var rx0fastlock $RXPRESETSFILE)
if [ "$FLOCK" = "ON" ]; then
  FASTLOCK="--fastlock"
else
  FASTLOCK=""
fi

if [ "$GAIN" -lt 10 ]; then
  GAIN_LIME="0.0$GAIN"
else
  GAIN_LIME="0.$GAIN"
fi

if [ "$GAIN" = 100 ] && [ "$SDR" = "LIMEMINI" ]; then
 GAIN_LIME=1
fi

MODE_STARTUP=$(get_config_var startup $PCONFIGFILE)

if [ "$MODE_STARTUP" == "Button_rx_boot" ]; then
  if [ "$FREQ_OUTPUT" = "145.9" ] && [ "$SDR" = "LIMEMINI" ]; then
    GAIN_LIME="0.8"
  elif [ "$FREQ_OUTPUT" = "437" ] && [ "$SDR" = "LIMEMINI" ]; then
    GAIN_LIME="0.7"
  elif [ "$FREQ_OUTPUT" = "1255" ] && [ "$SDR" = "LIMEMINI" ]; then
    GAIN_LIME="1"
  fi
fi

# Look up the RTL-SDR Frequency error from the RTL-FM file
FREQOFFSET=$(get_config_var roffset $RTLPRESETSFILE)

if [ "$SDR" = "RTLSDR" ]; then
  KEY="rtl_sdr -p $FREQOFFSET -g $GAIN -f $FreqHz -s $SR_RTLSDR - 2>/dev/null "
  B=""
fi
if [ "$SDR" = "LIMEMINI" ]; then
  KEY="/home/pi/rpidatv/bin/limesdr_dump -f $FreqHz -b 5e6 -s $SR_RTLSDR -g $GAIN_LIME -l 256*256 |buffer"
  B="--s12"
fi

if [ "$MODULATION" != "DVB-S" ] && [ "$MODULATION" != "DVB-S2" ]; then
  if [ "$MODULATION" = "8PSK" ]; then
    MODULATION="DVB-S2"
    MODULATION_TX="DVBS2"
    CONST="8PSK"
  elif [ "$MODULATION" = "16APSK" ]; then
    MODULATION="DVB-S2"
    MODULATION_TX="DVBS2"
    CONST="16APSK"
  elif [ "$MODULATION" = "32APSK" ]; then
    MODULATION="DVB-S2"
    MODULATION_TX="DVBS2"
    CONST="32APSK"
  fi
else
  CONST="QPSK"
fi

if [ "$MODULATION" = "DVB-S" ]; then
  MODULATION_TX="DVBS"
fi

# Clean up
sudo rm fifo.264 >/dev/null 2>/dev/null
sudo rm videots >/dev/null 2>/dev/null
#sudo rm fifo.iq >/dev/null 2>/dev/null
sudo killall -9 hello_video.bin >/dev/null 2>/dev/null
sudo killall -9 hello_video2.bin >/dev/null 2>/dev/null
sudo killall leandvb >/dev/null 2>/dev/null
sudo killall ts2es >/dev/null 2>/dev/null
mkfifo fifo.264
mkfifo videots

#if [ "$1" == "-remote" ]; then
#  sudo rm fifo.iq >/dev/null 2>/dev/null
#  mkfifo fifo.iq
#fi

# Make sure that the screen background is all black
sudo killall fbi >/dev/null 2>/dev/null
sudo fbi -T 1 -noverbose -a $PATHSCRIPT"/images/Blank_Black.png"
(sleep 1; sudo killall -9 fbi >/dev/null 2>/dev/null) &  ## kill fbi once it has done its work

# Pipe the output from rtl-sdr to leandvb.  Then put videots in a fifo.

# Treat each display case differently

if [ "$MODE_OUTPUT" != "RPI_R" ]; then
  # Constellation and Parameters on
  if [ "$GRAPHICS" = "ON" ] && [ "$PARAMS" = "ON" ] && [ "$ETAT" = "OFF" ]; then
    sudo $KEY\
      | $PATHBIN"leandvb" $B --fd-pp 3 --fd-info 2 --fd-const 2 $FECDVB $FASTLOCK --sr $SYMBOLRATE --standard $MODULATION --const $CONST -f $SR_RTLSDR >videots 3>fifo.iq &
  fi

  # Constellation on, Parameters off
  if [ "$GRAPHICS" = "ON" ] && [ "$PARAMS" = "OFF" ] && [ "$ETAT" = "OFF" ]; then
    sudo $KEY\
      | $PATHBIN"leandvb" $B --fd-pp 3 --fd-const 2 $FECDVB $FASTLOCK --sr $SYMBOLRATE --standard $MODULATION --const $CONST -f $SR_RTLSDR >videots 3>fifo.iq &
  fi

  # Constellation off, Parameters on
  if [ "$GRAPHICS" = "OFF" ] && [ "$PARAMS" = "ON" ] && [ "$ETAT" = "OFF" ]; then
    sudo $KEY\
      | $PATHBIN"leandvb" $B --fd-pp 3 --fd-info 2 --fd-const 2 $FECDVB $FASTLOCK --sr $SYMBOLRATE --standard $MODULATION --const $CONST -f $SR_RTLSDR >videots 3>fifo.iq &
  fi

  # Constellation and Parameters off
  if [[ "$GRAPHICS" = "OFF" && "$PARAMS" = "OFF" ]] || [ "$ETAT" = "ON" ]; then
    sudo $KEY\
      | $PATHBIN"leandvb" $B $FECDVB $FASTLOCK --sr $SYMBOLRATE --standard $MODULATION --const $CONST -f $SR_RTLSDR >videots 3>/dev/null &
  fi

else
  netcat -u -4 -l $PORT > videots & # Côté écoute
  #netcat -u -4 -l $PORT_IQ > fifo.iq & # Côté écoute
fi

if [ "$1" == "-remote" ]; then
  netcat -u -4 $CLIENTIP $PORT < videots &
  #netcat -u -4 $CLIENTIP $PORT_IQ < fifo.iq &
fi

if [ "$ETAT" = "OFF" ] && [ "$1" != "-remote" ]; then
  # read videots and output video es
  $PATHBIN"ts2es" -video videots fifo.264 &
# Play the es from fifo.264 in either the H264 or MPEG-2 player.
  if [ "$ENCODING" = "H264" ]; then
    $PATHBIN"hello_video.bin" fifo.264 &
  else  # MPEG-2
    $PATHBIN"hello_video2.bin" fifo.264 &
  fi
elif [ "$ETAT" = "ON" ] && [ "$MODE_OUTPUT" != "RPI_R" ]; then
  if [ "$MODE_OUTPUT" = "LIMEMINI" ]; then
    $PATHBIN/"dvb2iq2" -i videots -s $SYMBOLRATEK -f $FECIQ \
            -r $UPSAMPLE -m $MODULATION_TX -c $CONST \
    |sudo $PATHBIN/"limesdr_send" -b 2.5e6 -r $UPSAMPLE -s $SYMBOLRATE -g $LIME_TX_GAINA -f $FREQ_TX"e6" &
  elif [ "$MODE_OUTPUT" = "IQ" ]; then
    $PATHSCRIPT"/ctlfilter.sh"
    $PATHSCRIPT"/ctlvco.sh"
    sudo $PATHBIN"/rpidatv" -i videots -s $SYMBOLRATEK -c $FECNUM"/"$FECDEN -f $FREQTX -p $RF_GAIN -m $MODE_OUTPUT -x $PIN_I -y $PIN_Q &
  fi
fi

if [ "$1" == "-remote_rxtotx_on" ]; then

  CMDFILE="/home/pi/tmp/rpi_command.txt"

  ###################################################
    IP_DISTANT=$(get_config_var rpi_ip_distant $PCONFIGFILE)
    RPI_USER=$(get_config_var rpi_user_remote $PCONFIGFILE)
    RPI_PW=$(get_config_var rpi_pw_remote $PCONFIGFILE)
    set_config_var ack "KO" $ACKFILE
    ACK=$(get_config_var ack $ACKFILE)
    N=0
  ###################################################

/bin/cat <<EOM >$CMDFILE
 (sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

 sudo /home/pi/rpidatv/scripts/leandvbgui2.sh 2>&1
 $PATHSCRIPT"/lime_ptt.sh" &

ENDSSH
      ) &
EOM

        source "$CMDFILE"
  exit
fi

if [ "$1" == "-remote_rxtotx_off" ]; then

  CMDFILE="/home/pi/tmp/rpi_command.txt"

  ###################################################
    IP_DISTANT=$(get_config_var rpi_ip_distant $PCONFIGFILE)
    RPI_USER=$(get_config_var rpi_user_remote $PCONFIGFILE)
    RPI_PW=$(get_config_var rpi_pw_remote $PCONFIGFILE)
    set_config_var ack "KO" $ACKFILE
    ACK=$(get_config_var ack $ACKFILE)
    N=0
  ###################################################

/bin/cat <<EOM >$CMDFILE
 (sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

 sudo /home/pi/rpidatv/scripts/b.sh 2>&1

ENDSSH
      ) &
EOM

        source "$CMDFILE"
  exit
fi

#fi

# Notes:
# --fd-pp FDNUM        Dump preprocessed IQ data to file descriptor
# --fd-info FDNUM      Output demodulator status to file descriptor
# --fd-const FDNUM     Output constellation and symbols to file descr
# --fd-spectrum FDNUM  Output spectrum to file descr
