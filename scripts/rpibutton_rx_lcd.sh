#! /bin/bash
RXPRESETSFILE="/home/pi/rpidatv/scripts/rx_presets.txt"

############### PIN DEFINITION ###########"
#SR=GPIO 26 / Header 37
button=26

receive=0;

rx=1;
NEW_FREQ_RX=145.9;
NEW_SR=125;
MODULATION=DVB-S;
NEW_FEC=7;

gpio -g mode $button in
gpio -g mode $button up

############### IN/OUT CONFIG FILE
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

##################### RECEIVER ##############
do_view_config()
{
  rm /home/pi/tmp/BATC_Black.png >/dev/null 2>/dev/null

  convert /home/pi/rpidatv/scripts/images/BATC_Black.png -gravity North -pointsize 45 -fill white -annotate 0 "\nFreq: $FREQ MHz SR: $SYMBOLRATEK Ks" /home/pi/tmp/BATC_Black.png

  sudo fbi -T 1 -noverbose -a /home/pi/tmp/BATC_Black.png >/dev/null 2>/dev/null
  (sleep 1; sudo killall -9 fbi >/dev/null 2>/dev/null) &

  i=0
  while [ $i -ne 8 ] ; do
    do_process_button
    sleep 0.5
    i=$(($i + 1))
  done
}
do_stop_receiver()
{
  sudo killall -9 rpidatvgui >/dev/null 2>/dev/null
  sudo killall -9 leandvb >/dev/null 2>/dev/null
  sudo killall -9 hello_video.bin >/dev/null 2>/dev/null
  sudo killall -9 rtl_sdr >/dev/null 2>/dev/null
  if [ "$RXKEY" == "LIMEMINI" ]; then
   sudo killall limesdr_dump >/dev/null 2>/dev/null
   /home/pi/rpidatv/bin/limesdr_stopchannel
  fi
  receive=0;
}

do_receive()
{
  RXKEY=$(get_config_var rx0sdr $RXPRESETSFILE)
  if pgrep -x "rtl_tcp" > /dev/null; then
    # rtl_tcp is running, so kill it, pause and really kill it
    killall rtl_tcp >/dev/null 2>/dev/null
    sleep 0.5
    sudo killall -9 rtl_tcp >/dev/null 2>/dev/null
  fi

  if ! pgrep -x "fbcp" > /dev/null; then
    # fbcp is not running, so start it
    fbcp &
  fi

    /home/pi/rpidatv/bin/rpidatvgui 0 1  >/dev/null 2>/dev/null &

  receive=1;

}

do_refresh_config()
{
        SYMBOLRATEK=$(get_config_var rx0sr $RXPRESETSFILE)
        FREQ=$(get_config_var rx0frequency $RXPRESETSFILE)
}

do_process_button()
{
	if [ `gpio -g read $button` = 0 ]; then

		 case "$rx" in
			1)
				rx=2;
        NEW_FREQ_RX=145.9;
        NEW_SR=250;
			;;
			2)
				rx=3;
        NEW_FREQ_RX=437;
        NEW_SR=125;
        MODULATION=DVB-S;
        NEW_FEC=7;
			;;
			3)
				rx=4;
        NEW_FREQ_RX=437;
        NEW_SR=250;
        MODULATION=DVB-S;
        NEW_FEC=7;
			;;
			4)
				rx=5;
        NEW_FREQ_RX=1255;
        NEW_SR=250;
			;;
      5)
				rx=1;
        NEW_FREQ_RX=145.9;
        NEW_SR=125;
			;;
			*)
				rx=1;
        NEW_FREQ_RX=145.9;
        NEW_SR=125;
			;;
		esac
		set_config_var rx0frequency "$NEW_FREQ_RX" $RXPRESETSFILE
    set_config_var rx0sr "$NEW_SR" $RXPRESETSFILE

    if [ "$receive" == 1 ]; then
      do_stop_receiver
    fi
    do_refresh_config
    do_view_config
		do_receive
	fi

}

##################### MAIN PROGRAM ##############
set_config_var rx0frequency "$NEW_FREQ_RX" $RXPRESETSFILE
set_config_var rx0sr "$NEW_SR" $RXPRESETSFILE
set_config_var rx0modulation "$MODULATION" $RXPRESETSFILE
set_config_var rx0fec "$NEW_FEC" $RXPRESETSFILE

do_refresh_config
do_view_config
do_receive
while true; do

        do_process_button

sleep 0.5

done
