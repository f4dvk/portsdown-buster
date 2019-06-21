#! /bin/bash

############ Set Environment Variables ###############

PATHSCRIPT=/home/pi/rpidatv/scripts
PATHRPI=/home/pi/rpidatv/bin
PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
PATHCONFIGS="/home/pi/rpidatv/scripts/configs"  ## Path to config files

############ Function to Read/Write Config File ###############

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

sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

  set_config_var modeoutput "$MODE_OUTPUT_R" $PCONFIGFILE
  set_config_var freqoutput "$FREQ_OUTPUT" $PCONFIGFILE
  set_config_var symbolrate "$SYMBOLRATEK" $PCONFIGFILE
  set_config_var modulation "$MODULATION" $PCONFIGFILE
  set_config_var limegain "$LIME_GAIN" $PCONFIGFILE
  set_config_var encoding "$ENCODING" $PCONFIGFILE
  set_config_var format "$FORMAT" $PCONFIGFILE
  set_config_var frames "$FRAME" $PCONFIGFILE
  set_config_var pilots "$PILOT" $PCONFIGFILE
  set_config_var fec "$FEC" $PCONFIGFILE

ENDSSH

exit
