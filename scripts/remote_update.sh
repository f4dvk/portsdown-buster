#! /bin/bash

############ Set Environment Variables ###############

PATHSCRIPT=/home/pi/rpidatv/scripts
PATHRPI=/home/pi/rpidatv/bin
PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
PATHCONFIGS="/home/pi/rpidatv/scripts/configs"  ## Path to config files
PATHCONFIGRX="/home/pi/rpidatv/scripts/rx_presets.txt"

CMDFILE="/home/pi/tmp/rpi_command.txt"

############ Function to Read / Write Config File ###############

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

set_config_var() {
lua - "$1" "$2" "$3"<<EOF > "$3.bak2"
local key=assert(arg[1])
local value=assert(arg[2])
local fn=assert(arg[3])
local file=assert(io.open(fn))
local made_change=false
for line in file:lines() do
if line:match("^#?%s*"..key.."=.*$") then
line=key.."="..value
made_change=true
end
print(line)
end
if not made_change then
print(key.."="..value)
end
EOF
mv "$3.bak2" "$3"
}
###################################################
  IP_DISTANT=$(get_config_var rpi_ip_distant $PCONFIGFILE)
  RPI_USER=$(get_config_var rpi_user_remote $PCONFIGFILE)
  RPI_PW=$(get_config_var rpi_pw_remote $PCONFIGFILE)
###################################################

if [ "$1" == "-first" ]; then
  set_config_var modeoutput "RPI_R" $PCONFIGFILE
  set_config_var modeinput "CAMH264" $PCONFIGFILE

  /bin/cat <<EOM >$CMDFILE
   (sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

   sed -i '/\(^modeinput=\).*/s//\1"IPTSIN"/' $PCONFIGFILE

  ENDSSH
        ) &
  EOM

        source "$CMDFILE"

exit
fi

if [ "$1" == "-rx" ]; then
  FREQ_RX=$(get_config_var rx0frequency $PATHCONFIGRX)
  SR_RX=$(get_config_var rx0sr $PATHCONFIGRX)
  FEC_RX=$(get_config_var rx0fec $PATHCONFIGRX)
  SAMPLERATE_RX=$(get_config_var rx0samplerate $PATHCONFIGRX)
  GAIN_RX=$(get_config_var rx0gain $PATHCONFIGRX)
  MODULATION_RX=$(get_config_var rx0modulation $PATHCONFIGRX)
  ENCODING_RX=$(get_config_var rx0encoding $PATHCONFIGRX)
  GRAPHICS_RX=$(get_config_var rx0graphics $PATHCONFIGRX)
  FL_RX=$(get_config_var rx0fastlock $PATHCONFIGRX)

  /bin/cat <<EOM >$CMDFILE
   (sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

   sed -i '/\(^rx0frequency=\).*/s//\1$FREQ_RX/' $PATHCONFIGRX
   sed -i '/\(^rx0sr=\).*/s//\1$SR_RX/' $PATHCONFIGRX
   sed -i '/\(^rx0fec=\).*/s//\1$FEC_RX/' $PATHCONFIGRX
   sed -i '/\(^rx0samplerate=\).*/s//\1$SAMPLERATE_RX/' $PATHCONFIGRX
   sed -i '/\(^rx0gain=\).*/s//\1$GAIN_RX/' $PATHCONFIGRX
   sed -i '/\(^rx0modulation=\).*/s//\1$MODULATION_RX/' $PATHCONFIGRX
   sed -i '/\(^rx0encoding=\).*/s//\1$ENCODING_RX/' $PATHCONFIGRX
   sed -i '/\(^rx0graphics=\).*/s//\1$GRAPHICS_RX/' $PATHCONFIGRX
   sed -i '/\(^rx0fastlock=\).*/s//\1$FL_RX/' $PATHCONFIGRX

  ENDSSH
        ) &
  EOM

        source "$CMDFILE"
  exit
fi

if [ "$1" == "-init" ]; then
  /bin/cat <<EOM >$CMDFILE
   (sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

   sed -i '/\(^modeinput=\).*/s//\1"IPTSIN"/' $PCONFIGFILE

  ENDSSH
        ) &
  EOM

        source "$CMDFILE"

fi

###################################################
  MODE_OUTPUT_R=$(get_config_var remoteoutput $PCONFIGFILE)
  FREQ_OUTPUT=$(get_config_var freqoutput $PCONFIGFILE)
  SYMBOLRATEK=$(get_config_var symbolrate $PCONFIGFILE)
  MODULATION=$(get_config_var modulation $PCONFIGFILE)
  LIME_GAIN=$(get_config_var limegain $PCONFIGFILE)
  ENCODING=$(get_config_var encoding $PCONFIGFILE)
  FORMAT=$(get_config_var format $PCONFIGFILE)
  FRAME=$(get_config_var frames $PCONFIGFILE)
  PILOT=$(get_config_var pilots $PCONFIGFILE)
  FEC=$(get_config_var fec $PCONFIGFILE)

##############################################################
/bin/cat <<EOM >$CMDFILE
 (sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

 sed -i '/\(^modeoutput=\).*/s//\1$MODE_OUTPUT_R/' $PCONFIGFILE
 sed -i '/\(^freqoutput=\).*/s//\1$FREQ_OUTPUT/' $PCONFIGFILE
 sed -i '/\(^symbolrate=\).*/s//\1$SYMBOLRATEK/' $PCONFIGFILE
 sed -i '/\(^modulation=\).*/s//\1$MODULATION/' $PCONFIGFILE
 sed -i '/\(^limegain=\).*/s//\1$LIME_GAIN/' $PCONFIGFILE
 sed -i '/\(^encoding=\).*/s//\1$ENCODING/' $PCONFIGFILE
 sed -i '/\(^format=\).*/s//\1$FORMAT/' $PCONFIGFILE
 sed -i '/\(^frames=\).*/s//\1$FRAME/' $PCONFIGFILE
 sed -i '/\(^pilots=\).*/s//\1$PILOT/' $PCONFIGFILE
 sed -i '/\(^fec=\).*/s//\1$FEC/' $PCONFIGFILE

ENDSSH
      ) &
EOM

      source "$CMDFILE"

exit
