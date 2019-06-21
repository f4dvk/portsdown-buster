#! /bin/bash

############ Set Environment Variables ###############

PATHSCRIPT=/home/pi/rpidatv/scripts
PATHRPI=/home/pi/rpidatv/bin
PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
PATHCONFIGS="/home/pi/rpidatv/scripts/configs"  ## Path to config files

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
  IP_DISTANT=172.24.1.1
  RPI_USER=pi
  RPI_PW=raspberry
###################################################

###################### Commande distante ###########################

sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

 $PATHSCRIPT"/a.sh" >/dev/null 2>/dev/null &
 $PATHSCRIPT"/TXstartextras.sh" >/dev/null 2>/dev/null &
 $PATHSCRIPT"/lime_ptt.sh" &

ENDSSH

exit
