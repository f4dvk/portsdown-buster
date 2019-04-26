PATHSCRIPT=/home/pi/rpidatv/scripts
CONFIGFILE=$PATHSCRIPT"/portsdown_config.txt"
RXPRESETSFILE="/home/pi/rpidatv/scripts/rx_presets.txt"
PATHRPI=/home/pi/rpidatv/bin
PATHBIN="/home/pi/rpidatv/bin/"


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
  sudo killall -9 rx_gpio >/dev/null 2>/dev/null
  sudo killall -9 leandvb >/dev/null 2>/dev/null
  sudo killall -9 hello_video.bin >/dev/null 2>/dev/null
  sudo killall -9 rtl_sdr >/dev/null 2>/dev/null
  if [ "$RXKEY" == "LIMEMINI" ]; then
   sudo killall limesdr_dump >/dev/null 2>/dev/null
   /home/pi/rpidatv/bin/limesdr_stopchannel
  fi
  sudo fbi -T 1 -noverbose -a /home/pi/rpidatv/scripts/images/BATC_Black.png
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

    /home/pi/rpidatv/bin/rx_gpio 0 1  >/dev/null 2>/dev/null &

}

do_refresh_config()
{
        SYMBOLRATEK=$(get_config_var rx0sr $RXPRESETSFILE)
        FEC=$(get_config_var rx0fec $RXPRESETSFILE)
        FREQ=$(get_config_var rx0frequency $RXPRESETSFILE)
        MODULATION=$(get_config_var rx0modulation $RXPRESETSFILE)
}

do_process_button()
{
	 if [ `gpio -g read $button_SR` = 1 ]&&[ "$SYMBOLRATEK" != 333 ]&&[ "$FREQ" != 145.9 ] ; then

                        NEW_SR=333;
                        NEW_FEC=7;

                set_config_var rx0sr "$NEW_SR" $RXPRESETSFILE
                set_config_var rx0fec "$NEW_FEC" $RXPRESETSFILE

                echo $NEW_SR
                do_refresh_config
        fi

        if [ `gpio -g read $button_SR` = 0 ]&&[ "$SYMBOLRATEK" != 250 ]&&[ "$FREQ" != 145.9 ] ; then

                        NEW_SR=250;
                        NEW_FEC=1;

                set_config_var rx0sr "$NEW_SR" $RXPRESETSFILE
                set_config_var rx0fec "$NEW_FEC" $RXPRESETSFILE

                echo $NEW_SR
                do_refresh_config
        fi

        if [ `gpio -g read $button_0` = 1 ]&&[ `gpio -g read $button_1` = 1 ]&&[ "$FREQ" != 437 ] ; then

                                NEW_FREQ_RX=437;
                                MODULATION=DVB-S;

                set_config_var rx0frequency "$NEW_FREQ_RX" $RXPRESETSFILE
                set_config_var rx0modulation "$MODULATION" $RXPRESETSFILE

                echo $NEW_FREQ_RX
                do_refresh_config
        fi

        if [ `gpio -g read $button_0` = 0 ]&&[ `gpio -g read $button_1` = 1 ]&&[ "$FREQ" != 145.9 ] ; then

                                NEW_FREQ_RX=145.9;
                                NEW_SR=125;
                                MODULATION=DVB-S2;

                set_config_var rx0frequency "$NEW_FREQ_RX" $RXPRESETSFILE
                set_config_var rx0sr "$NEW_SR" $RXPRESETSFILE
                set_config_var rx0modulation "$MODULATION" $RXPRESETSFILE

                echo $NEW_FREQ_RX
                do_refresh_config
        fi

        if [ `gpio -g read $button_0` = 1 ]&&[ `gpio -g read $button_1` = 0 ]&&[ "$FREQ" != 1255 ] ; then

                                NEW_FREQ_RX=1255;
                                MODULATION=DVB-S;

                set_config_var rx0frequency "$NEW_FREQ_RX" $RXPRESETSFILE
                set_config_var rx0modulation "$MODULATION" $RXPRESETSFILE

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
while true; do

        do_process_button

sleep 0.5

done
