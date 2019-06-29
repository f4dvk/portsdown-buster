#! /bin/bash

############ Set Environment Variables ###############

PATHSCRIPT=/home/pi/rpidatv/scripts
PATHRPI=/home/pi/rpidatv/bin
PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
PATHCONFIGS="/home/pi/rpidatv/scripts/configs"  ## Path to config files

CMDFILE="/home/pi/tmp/rpi_command.txt"

############ Function to Read Config File ###############

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

###################################################
  IP_DISTANT=$(get_config_var rpi_ip_distant $PCONFIGFILE)
  RPI_USER=$(get_config_var rpi_user_remote $PCONFIGFILE)
  RPI_PW=$(get_config_var rpi_pw_remote $PCONFIGFILE)
###################################################
  MODE_OUTPUT_R=$(get_config_var modeoutput_r $PCONFIGFILE)
  FREQ_OUTPUT=$(get_config_var freqoutput $PCONFIGFILE)
  SYMBOLRATEK=$(get_config_var symbolrate $PCONFIGFILE)
  MODULATION=$(get_config_var modulation $PCONFIGFILE)
  LIME_GAIN=$(get_config_var limegain $PCONFIGFILE)
  ENCODING=$(get_config_var encoding $PCONFIGFILE)
  FORMAT=$(get_config_var format $PCONFIGFILE)
  FRAME=$(get_config_var frames $PCONFIGFILE)
  PILOT=$(get_config_var pilots $PCONFIGFILE)
  FEC=$(get_config_var fec $PCONFIGFILE)

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
