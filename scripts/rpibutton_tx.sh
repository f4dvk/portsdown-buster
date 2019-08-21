PATHSCRIPT=/home/pi/rpidatv/scripts
CONFIGFILE=$PATHSCRIPT"/portsdown_config.txt"

############### PIN DEFINITION ###########"
#button_0=GPIO 4 / Header 7
button_0=4
#button_1=GPIO 14 / Header 8
button_1=14
#SR=GPIO 17 / Header 11
button_SR=17
#PTT=GPIO18 /Header 12
PTT=18

transmit=0;

gpio -g mode $button_0 in
gpio -g mode $button_1 in
gpio -g mode $button_SR in

gpio -g mode $button_0 up
gpio -g mode $button_1 up
gpio -g mode $button_SR up

gpio -g mode $PTT in
gpio -g mode $PTT up

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

##################### TRANSMIT ##############

do_transmit()
{
        do_refresh_config

        sleep 0.5
        sudo $PATHSCRIPT"/a.sh" >/dev/null 2>/dev/null &
        $PATHSCRIPT"/lime_ptt.sh" &
        sleep 0.5
}

do_stop_transmit()
{
 	sleep 0.5
        sudo $PATHSCRIPT"/b.sh" 2>/dev/null &
        sleep 0.5
}

do_refresh_config()
{
        MODE_INPUT=$(get_config_var modeinput $CONFIGFILE)
        SYMBOLRATEK=$(get_config_var symbolrate $CONFIGFILE)
        FEC=$(get_config_var fec $CONFIGFILE)
        FREQ=$(get_config_var freqoutput $CONFIGFILE)
        MODULATION=$(get_config_var modulation $CONFIGFILE)
}

do_process_button()
{
	     if [ `gpio -g read $button_SR` = 1 ]&&[ "$SYMBOLRATEK" != 333 ]&&[ "$FREQ" != 145.9 ]&&[ "$FREQ" != 437 ] ; then

                        NEW_SR=333;
                        NEW_FEC=7;
                        MOD=0;

                set_config_var symbolrate "$NEW_SR" $CONFIGFILE
                set_config_var fec "$NEW_FEC" $CONFIGFILE

                echo $NEW_SR
                do_refresh_config
        fi

        if [ `gpio -g read $button_SR` = 0 ]&&[ "$SYMBOLRATEK" != 250 ]&&[ "$FREQ" != 145.9 ]&&[ "$FREQ" != 437 ] ; then

                        NEW_SR=250;
                        NEW_FEC=1;
                        MOD=0;

                set_config_var symbolrate "$NEW_SR" $CONFIGFILE
                set_config_var fec "$NEW_FEC" $CONFIGFILE

                echo $NEW_SR
                do_refresh_config
        fi

        if [ `gpio -g read $button_0` = 1 ]&&[ `gpio -g read $button_1` = 1 ]&&[ "$MOD" != 1 ]&&[ `gpio -g read $button_SR` = 1 ] ; then

                                NEW_FREQ_OUTPUT=437;
                                MODULATION=DVB-S;
                                NEW_SR=333;
                                FEC=7;
                                MOD=1;

                set_config_var freqoutput "$NEW_FREQ_OUTPUT" $CONFIGFILE
                set_config_var symbolrate "$NEW_SR" $CONFIGFILE
                set_config_var modulation "$MODULATION" $CONFIGFILE
                set_config_var fec "$FEC" $CONFIGFILE

                echo $NEW_FREQ_OUTPUT
                do_refresh_config
        fi

        if [ `gpio -g read $button_0` = 1 ]&&[ `gpio -g read $button_1` = 1 ]&&[ "$MOD" != 4 ]&&[ `gpio -g read $button_SR` = 0 ] ; then

                                NEW_FREQ_OUTPUT=437;
                                MODULATION=DVB-S;
                                NEW_SR=125;
                                FEC=7;
                                MOD=4;

                set_config_var freqoutput "$NEW_FREQ_OUTPUT" $CONFIGFILE
                set_config_var symbolrate "$NEW_SR" $CONFIGFILE
                set_config_var modulation "$MODULATION" $CONFIGFILE
                set_config_var fec "$FEC" $CONFIGFILE

                echo $NEW_FREQ_OUTPUT
                do_refresh_config
        fi

        if [ `gpio -g read $button_0` = 0 ]&&[ `gpio -g read $button_1` = 1 ]&&[ "$FREQ" != 145.9 ] ; then

                                NEW_FREQ_OUTPUT=145.9;
                                NEW_SR=125;
                                MODULATION=DVB-S;
                                FEC=7;
                                MOD=0;


                set_config_var freqoutput "$NEW_FREQ_OUTPUT" $CONFIGFILE
                set_config_var symbolrate "$NEW_SR" $CONFIGFILE
                set_config_var modulation "$MODULATION" $CONFIGFILE
                set_config_var fec "$FEC" $CONFIGFILE

                echo $NEW_FREQ_OUTPUT
                do_refresh_config
        fi

        if [ `gpio -g read $button_0` = 1 ]&&[ `gpio -g read $button_1` = 0 ]&&[ "$FREQ" != 1255 ] ; then

                                NEW_FREQ_OUTPUT=1255;
                                MODULATION=DVB-S;
                                FEC=7;
                                MOD=0;

                set_config_var freqoutput "$NEW_FREQ_OUTPUT" $CONFIGFILE
                set_config_var modulation "$MODULATION" $CONFIGFILE
                set_config_var fec "$FEC" $CONFIGFILE

                echo $NEW_FREQ_OUTPUT
                do_refresh_config
        fi

        if [ `gpio -g read $PTT` = 0 ]&&[ "$transmit" = 0 ] ; then

                transmit=1;
                do_transmit
                echo "Emission"
        fi

        if [ `gpio -g read $PTT` = 1 ]&&[ "$transmit" = 1 ] ; then

                do_stop_transmit
                transmit=0;
                echo "Standby"
	fi
}

##################### MAIN PROGRAM ##############

do_refresh_config
MOD=0;
while true; do

        do_process_button

sleep 0.5

done
