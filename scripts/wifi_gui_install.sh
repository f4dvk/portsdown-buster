#! /bin/bash

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
 echo "ssid=Non connecté" > /home/pi/rpidatv/scripts/wifi_get.txt
 exit
else
 SSID
fi

while [ $? == 0 ]; do
 ssid
 SSID
done

cat /home/pi/ssid1.txt | sed 's/.* //;s/ESSID/ssid/g;s/ //g;s/"//g;s/:/=/g' > /home/pi/rpidatv/scripts/wifi_get.txt

rm /home/pi/ssid1.txt

########################################################################

elif [ "$1" == "-scan" ]; then

scan()
{
 sudo iwlist wlan0 scan > scan.txt
}

scan

while [ $? != 0 ]; do
 scan
done

cat /home/pi/scan.txt | grep 'ESSID' | sed 's/ESSID/ssid/g;s/ //g;s/"//g;s/:/ =/g' | awk '/ssid/ {i=i+1} {print "ssid"i$2}' > /home/pi/rpidatv/scripts/wifi_scan.txt

rm /home/pi/scan.txt

fi

exit
