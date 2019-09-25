#!/bin/bash
RXPRESETSFILE="/home/pi/rpidatv/scripts/longmynd_config.txt"

############### PIN DEFINITION ###########"
#button_0=GPIO 4 / Header 7
button_0=4
#button_1=GPIO 14 / Header 8
button_1=14
#SR=GPIO 17 / Header 11
button_SR=17
#RX=GPIO15 /Header 10
RX=15

receive=0;

gpio -g mode $button_0 in
gpio -g mode $button_1 in
gpio -g mode $button_SR in

gpio -g mode $button_0 up
gpio -g mode $button_1 up
gpio -g mode $button_SR up

gpio -g mode $RX in
gpio -g mode $RX up



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

do_stop_receiver()
{
  sudo killall -9 lmhv2.sh >/dev/null 2>/dev/null
  sudo killall -9 rpidatvgui >/dev/null 2>/dev/null
  sudo killall -9 hello_video.bin >/dev/null 2>/dev/null
  sudo killall -9 hello_video2.bin >/dev/null 2>/dev/null
  sudo killall fbi >/dev/null 2>/dev/null

  sudo fbi -T 1 -noverbose -a /home/pi/rpidatv/scripts/images/BATC_Black.png
}

do_receive()
{
  if ! pgrep -x "fbcp" > /dev/null; then
    # fbcp is not running, so start it
    fbcp &
  fi

    /home/pi/rpidatv/bin/rpidatvgui 0 2  >/dev/null 2>/dev/null &
}

do_refresh_config()
{
        SYMBOLRATEK=$(get_config_var sr1 $RXPRESETSFILE)
        FREQ=$(get_config_var freq1 $RXPRESETSFILE)
}

do_process_button()
{
         if [ `gpio -g read $button_SR` = 1 ]&&[ "$SYMBOLRATEK" != 250 ]&&[ "$FREQ" != 145900 ]&&[ "$FREQ" != 1255000 ] ; then

                        NEW_SR=250;
                        MOD=0;

                set_config_var sr1 "$NEW_SR" $RXPRESETSFILE

                echo $NEW_SR
                do_refresh_config
        fi

        if [ `gpio -g read $button_SR` = 0 ]&&[ "$SYMBOLRATEK" != 125 ]&&[ "$FREQ" != 145900 ]&&[ "$FREQ" != 1255000 ] ; then

                        NEW_SR=125;
                        MOD=0;

                set_config_var sr1 "$NEW_SR" $RXPRESETSFILE

                echo $NEW_SR
                do_refresh_config
        fi

        if [ `gpio -g read $button_0` = 1 ]&&[ `gpio -g read $button_1` = 1 ]&&[ "$FREQ" != 437000 ] ; then

                                NEW_FREQ_RX=437000;
                                MOD=0;

                set_config_var freq1 "$NEW_FREQ_RX" $RXPRESETSFILE

                echo $NEW_FREQ_RX
                do_refresh_config
        fi

        if [ `gpio -g read $button_0` = 0 ]&&[ `gpio -g read $button_1` = 1 ]&&[ "$MOD" != 1 ] ; then

                                NEW_FREQ_RX=145900;
                                NEW_SR=125;
                                MOD=1;

                set_config_var freq1 "$NEW_FREQ_RX" $RXPRESETSFILE
                set_config_var sr1 "$NEW_SR" $RXPRESETSFILE

                echo $NEW_FREQ_RX
                do_refresh_config
        fi

        if [ `gpio -g read $button_0` = 1 ]&&[ `gpio -g read $button_1` = 0 ]&&[ `gpio -g read $button_SR` = 1 ]&&[ "$MOD" != 2 ] ; then

                                NEW_FREQ_RX=145900;
                                NEW_SR=250;
                                MOD=2;

                set_config_var freq1 "$NEW_FREQ_RX" $RXPRESETSFILE
                set_config_var sr1 "$NEW_SR" $RXPRESETSFILE

                echo $NEW_FREQ_RX
                do_refresh_config
        fi

        if [ `gpio -g read $button_0` = 1 ]&&[ `gpio -g read $button_1` = 0 ]&&[ "$FREQ" != 1255000 ]&&[ `gpio -g read $button_SR` = 0 ] ; then

                                NEW_FREQ_RX=1255000;
                                NEW_SR=250;
                                MOD=0;

                set_config_var freq1 "$NEW_FREQ_RX" $RXPRESETSFILE
                set_config_var sr1 "$NEW_SR" $RXPRESETSFILE

                echo $NEW_FREQ_RX
                do_refresh_config
        fi

        if [ `gpio -g read $RX` = 0 ]&&[ "$receive" = 0 ] ; then

                receive=1;
                do_receive
                echo "Reception"
        fi

        if [ `gpio -g read $RX` = 1 ]&&[ "$receive" = 1 ] ; then

                do_stop_receiver
                receive=0;
                echo "Standby"

        fi

}

##################### MAIN PROGRAM ##############

do_refresh_config
RX_MODE=$(get_config_var mode $RXPRESETSFILE)
if [ "$RX_MODE" == "sat" ]; then
  set_config_var mode "terr" $RXPRESETSFILE
fi
MOD=0;
while true; do

        do_process_button

sleep 0.5

done
