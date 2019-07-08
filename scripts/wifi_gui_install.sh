#! /bin/bash

PCONFIGWIFI="/home/pi/rpidatv/scripts/wifi_config.txt"

########################################################################

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

########################################################################

if [ "$1" == "-get" ]; then

ssid()
{
iwgetid >/dev/null 2>/dev/null > /home/pi/ssid1.txt
}

SSID()
{
 cat /home/pi/ssid1.txt | grep 'ESSID:""' >/dev/null 2>/dev/null
}

ssid

if [ $? != 0 ]; then
 echo "ssid=Déconnecté" > /home/pi/rpidatv/scripts/wifi_get.txt
 exit
else
 SSID
fi

while [ $? == 0 ]; do
 ssid
 SSID
done

cat /home/pi/ssid1.txt | sed 's/.* //;s/ESSID/ssid/g;s/ //g;s/""/Déconnecté/g;s/"//g;s/:/=/g' > /home/pi/rpidatv/scripts/wifi_get.txt

rm /home/pi/ssid1.txt

if [ -s "/home/pi/rpidatv/scripts/wifi_get.txt" ];then
  exit
else
  echo "ssid=Déconnecté" > /home/pi/rpidatv/scripts/wifi_get.txt
fi

########################################################################

elif [ "$1" == "-scan" ]; then

scan()
{
 sudo iwlist wlan0 scan > /home/pi/scan.txt
}

scan

while [ $? != 0 ]; do
 scan
done

cat /home/pi/scan.txt | grep 'ESSID' | sed 's/ESSID/ssid/g;s/ //g;s/"//g;s/:/ =/g;$assid =' | awk '/ssid/ {i=i+1} {print "ssid"i$2}' > /home/pi/rpidatv/scripts/wifi_scan.txt

rm /home/pi/scan.txt

########################################################################

elif [ "$1" == "-install" ]; then
  SSID=$(get_config_var ssid $PCONFIGWIFI)
  PW=$(get_config_var password $PCONFIGWIFI)

  PSK_TEXT=$(wpa_passphrase "$SSID" "$PW" | grep 'psk=' | grep -v '#psk')

  PATHCONFIGS="/home/pi/rpidatv/scripts/configs"  ## Path to config files

  ## Build text for supplicant file
  ## Include Country (required for Stretch)

  rm $PATHCONFIGS"/wpa_text.txt"

  echo -e "country=FR" >> $PATHCONFIGS"/wpa_text.txt"
  echo -e "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev" >> $PATHCONFIGS"/wpa_text.txt"
  echo -e "update_config=1" >> $PATHCONFIGS"/wpa_text.txt"
  echo -e "network={" >> $PATHCONFIGS"/wpa_text.txt"
  echo -e "    ssid="\"""$SSID"\"" >> $PATHCONFIGS"/wpa_text.txt"
  echo -e "   "$PSK_TEXT >> $PATHCONFIGS"/wpa_text.txt"
  echo -e "    scan_ssid=1" >> $PATHCONFIGS"/wpa_text.txt"
  echo -e "    proto=RSN" >> $PATHCONFIGS"/wpa_text.txt"
  echo -e "    key_mgmt=WPA-PSK" >> $PATHCONFIGS"/wpa_text.txt"
  echo -e "    auth_alg=OPEN" >> $PATHCONFIGS"/wpa_text.txt"
  echo -e "}" >>  $PATHCONFIGS"/wpa_text.txt"

  ## Copy the existing wpa_supplicant file to work on

  sudo cp /etc/wpa_supplicant/wpa_supplicant.conf $PATHCONFIGS"/wpa_supcopy.txt"
  sudo chown pi:pi $PATHCONFIGS"/wpa_supcopy.txt"

  ## Define the parameters for the replace script

  lead='^##STARTNW'                         ## Marker for start of inserted text
  tail='^##ENDNW'                           ## Marker for end of inserted text
  CHANGEFILE=$PATHCONFIGS"/wpa_supcopy.txt" ## File requiring added text
  APPENDFILE=$PATHCONFIGS"/wpa_markers.txt" ## File containing both markers
  TRANSFILE=$PATHCONFIGS"/transfer.txt"     ## File used for transfer
  INSERTFILE=$PATHCONFIGS"/wpa_text.txt"    ## File to be included

  grep -q "$lead" "$CHANGEFILE"             ## Is the first marker already present?
  if [ $? -ne 0 ]; then
    sudo bash -c 'cat '$APPENDFILE' >> '$CHANGEFILE' '  ## If not append the markers
  fi

  ## Replace whatever is between the markers with the insert text

  sed -e "/$lead/,/$tail/{ /$lead/{p; r $INSERTFILE
        }; /$tail/p; d }" $CHANGEFILE >> $TRANSFILE

  sudo cp "$TRANSFILE" "$CHANGEFILE"          ## Copy from the transfer file
  rm $TRANSFILE                               ## Delete the transfer file

  ## Give the file root ownership and copy it back over the original

  sudo chown root:root $PATHCONFIGS"/wpa_supcopy.txt"
  sudo cp $PATHCONFIGS"/wpa_supcopy.txt" /etc/wpa_supplicant/wpa_supplicant.conf
  sudo rm $PATHCONFIGS"/wpa_supcopy.txt"

  sudo sed -i '/^##STARTNW/,$ !d' /etc/wpa_supplicant/wpa_supplicant.conf

  # Si présent, suppression démarrage auto hotspot
  if grep -q "iptables-restore < \/etc\/iptables.ipv4.nat" /etc/rc.local; then
    sudo sed -i "/iptables-restore < \/etc\/iptables.ipv4.nat/d" /etc/rc.local
  fi

  # Si présent, suppression inhibition dhcp wlan0
  if grep -q "denyinterfaces wlan0" /etc/dhcpcd.conf; then
   sudo sed -i "/denyinterfaces wlan0/d" /etc/dhcpcd.conf
  fi

  # Remplacer interfaces
  sudo cp /home/pi/rpidatv/scripts/configs/wifi_interfaces.txt /etc/network/interfaces

  ##bring wifi down and up again, then reset

  sudo ip link set wlan0 down
  sleep 1
  sudo ip link set wlan0 up
  sleep 1
  wpa_cli -i wlan0 reconfigure

  ## Make sure that it is not soft-blocked
  sleep 1
  sudo rfkill unblock 0

  sudo systemctl daemon-reload

  echo "ssid=" > $PCONFIGWIFI
  echo "password=" >> $PCONFIGWIFI

  sleep 1

fi

exit
