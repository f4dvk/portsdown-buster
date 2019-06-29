#! /bin/bash

############ Set Environment Variables ###############

PATHSCRIPT=/home/pi/rpidatv/scripts
PATHRPI=/home/pi/rpidatv/bin
PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
PATHCONFIGS="/home/pi/rpidatv/scripts/configs"  ## Path to config files

CMDFILE="/home/pi/tmp/rpi_command.txt"

############ Function to Read from Config File ###############

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

###################### Commande distante ###########################

/bin/cat <<EOM >$CMDFILE
 (sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

 /home/pi/rpidatv/scripts/TXstopextras.sh >/dev/null 2>/dev/null &
 sudo killall -9 rpidatv >/dev/null 2>/dev/null
 sudo killall -9 ffmpeg >/dev/null 2>/dev/null
 sudo killall -9 tcanim1v16 >/dev/null 2>/dev/null
 sudo killall -9 avc2ts >/dev/null 2>/dev/null
 sudo killall -9 netcat >/dev/null 2>/dev/null
 sudo killall -9 dvb2iq >/dev/null 2>/dev/null
 sudo killall -9 dvb2iq2 >/dev/null 2>/dev/null
 sudo killall -9 limesdr_send >/dev/null 2>/dev/null
 sleep 0.1
 sudo killall -9 avc2ts >/dev/null 2>/dev/null
 sudo killall -9 rpidatv >/dev/null 2>/dev/null
 sudo killall -9 limesdr_send >/dev/null 2>/dev/null
 sudo killall arecord >/dev/null 2>/dev/null
 gpio mode 29 out
 gpio write 29 0
 sudo killall a.sh >/dev/null 2>/dev/null
 sudo rm videoes >/dev/null 2>/dev/null
 sudo rm videots >/dev/null 2>/dev/null
 sudo rm netfifo >/dev/null 2>/dev/null
 sudo rm audioin.wav >/dev/null 2>/dev/null
 sleep 1
 /home/pi/rpidatv/bin/limesdr_stopchannel

ENDSSH
      ) &
      EOM

      source "$CMDFILE"

exit
