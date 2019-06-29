#! /bin/bash

############### PIN DEFINITION ###########"
#button_0=GPIO 26 / Header 37
button_0=26

transmit=0;

gpio -g mode $button_0 in
gpio -g mode $button_0 up

############ Set Environment Variables ###############

PATHSCRIPT=/home/pi/rpidatv/scripts
PATHRPI=/home/pi/rpidatv/bin
PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
PATHCONFIGS="/home/pi/rpidatv/scripts/configs"  ## Path to config files
JCONFIGFILE="/home/pi/rpidatv/scripts/jetson_config.txt"

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

do_process_button()
{
 if [ `gpio -g read $button_0` = 0 ]&&[ "$transmit" = 0 ]; then

 ###################### Commande locale ###########################

  # Call a.sh in an additional process to start the transmitter
  $PATHSCRIPT"/a.sh" >/dev/null 2>/dev/null &

  # Call TXstartextras.sh in an additional process
  $PATHSCRIPT"/TXstartextras.sh" >/dev/null 2>/dev/null &

  # Start the Viewfinder display
  v4l2-ctl --overlay=1 >/dev/null 2>/dev/null

 ###################### Commande distante ###########################

 sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

  /home/pi/rpidatv/scripts/a.sh >/dev/null 2>/dev/null &
  /home/pi/rpidatv/scripts/TXstartextras.sh >/dev/null 2>/dev/null &
  /home/pi/rpidatv/scripts/lime_ptt.sh &

 ENDSSH

 ########################

  transmit=1;
  echo "Emission"

 fi

 if [ `gpio -g read $button_0` = 1 ]&&[ "$transmit" = 1 ]; then

 ###################### Commande locale ###########################

  # Call TXstopextras.sh in an additional process
  $PATHSCRIPT"/TXstopextras.sh" >/dev/null 2>/dev/null &

  # Turn the Local Oscillator off
  sudo $PATHRPI"/adf4351" off

  # Kill the key processes as nicely as possible
  sudo killall -9 rpidatv >/dev/null 2>/dev/null
  sudo killall -9 ffmpeg >/dev/null 2>/dev/null
  sudo killall -9 tcanim1v16 >/dev/null 2>/dev/null
  sudo killall -9 avc2ts >/dev/null 2>/dev/null
  sudo killall -9 netcat >/dev/null 2>/dev/null
  sudo killall -9 dvb2iq >/dev/null 2>/dev/null
  sudo killall -9 dvb2iq2 >/dev/null 2>/dev/null
  sudo killall -9 limesdr_send >/dev/null 2>/dev/null
  # Then pause and make sure that avc2ts has really been stopped (needed at high SRs)
  sleep 0.1
  sudo killall -9 avc2ts >/dev/null 2>/dev/null

  # And make sure rpidatv has been stopped (required for brief transmit selections)
  sudo killall -9 rpidatv >/dev/null 2>/dev/null

  # And make sure limetx has been stopped
  sudo killall -9 limesdr_send >/dev/null 2>/dev/null

  # Stop the audio for CompVid mode
  sudo killall arecord >/dev/null 2>/dev/null

  # Display the BATC Logo on the Touchscreen
  #sudo fbi -T 1 -noverbose -a /home/pi/rpidatv/scripts/images/BATC_Black.png >/dev/null 2>/dev/null
  #(sleep 1; sudo killall -9 fbi >/dev/null 2>/dev/null) &  ## kill fbi once it has done its work

  # Kill a.sh which sometimes hangs during testing
  sudo killall a.sh >/dev/null 2>/dev/null

  # Check if driver for Logitech C270, C525 or C910 needs to be reloaded
  dmesg | grep -E -q "046d:0825|Webcam C525|046d:0821"
  if [ $? == 0 ]; then
    echo
    echo "Please wait for Webcam driver to be reset"
    sleep 3
    READY=0
    while [ $READY == 0 ]
    do
      v4l2-ctl --list-devices >/dev/null 2>/dev/null
      if [ $? == 1 ] ; then
        echo
        echo "Still waiting...."
        sleep 3
      else
        READY=1
      fi
    done
  fi

 ###################### Commande distante ###########################

 sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$IP_DISTANT 'bash -s' <<'ENDSSH'

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
  sleep 1
  /home/pi/rpidatv/bin/limesdr_stopchannel

 ENDSSH
  transmit=0;
  echo "Standby"

 fi
}

#########################################################

while true; do

 do_process_button

sleep 0.5

done
