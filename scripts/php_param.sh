#!/bin/bash

PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
PCONFIGFILEJETSON="/home/pi/rpidatv/scripts/jetson_config.txt"

############ FUNCTION TO READ / WRITE CONFIG FILE #############################

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

####################################################################

if [ "$1" == "set" ]; then
  set_config_var "$2" "$3" $PCONFIGFILE
  chmod 666 $PCONFIGFILE
fi
if [ "$1" == "jetson" ]; then
  set_config_var "$2" "$3" $PCONFIGFILEJETSON
  chmod 666 $PCONFIGFILEJETSON
fi

exit
