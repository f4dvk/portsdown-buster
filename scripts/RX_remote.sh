#! /bin/bash

############ Set Environment Variables ###############

PATHSCRIPT=/home/pi/rpidatv/scripts
PATHRPI=/home/pi/rpidatv/bin
PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
PATHCONFIGRX="/home/pi/rpidatv/scripts/rx_presets.txt"
PATHCONFIGS="/home/pi/rpidatv/scripts/configs"  ## Path to config files
ACKFILE="/home/pi/rpidatv/scripts/ack_remote.txt"

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
  set_config_var ack "KO" $ACKFILE
  ACK=$(get_config_var ack $ACKFILE)
  N=0
###################################################

###################### Commande distante ###########################
if [ "$1" == "-OFF" ]; then
#  while [ "$N" -lt 3 ] && [ "$ACK" == "KO" ]; do
/bin/cat <<EOM >$CMDFILE
 (sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

 sudo $PATHSCRIPT"/ack.sh" >/dev/null 2>/dev/null &
 $PATHSCRIPT"/b.sh" &

ENDSSH
      ) &
EOM

      source "$CMDFILE"

#sleep 200
#ACK=$(get_config_var ack $ACKFILE)
#if [ "$ACK" == "KO" ]; then
#  let N++
#fi
#  done

exit
fi

#while [ "$N" -lt 3 ] && [ "$ACK" == "KO" ]; do

/bin/cat <<EOM >$CMDFILE
 (sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

 sudo $PATHSCRIPT"/ack.sh" >/dev/null 2>/dev/null &
 $PATHSCRIPT"/leandvbgui2.sh" -remote >/dev/null 2>/dev/null &

ENDSSH
      ) &
EOM

      source "$CMDFILE"

#sleep 200
#ACK=$(get_config_var ack $ACKFILE)
#if [ "$ACK" == "KO" ]; then
#  let N++
#fi
#done

exit
