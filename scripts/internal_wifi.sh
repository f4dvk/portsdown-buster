#! /bin/bash


if [ "$1" == "-disable" ]; then
  if grep -q "^dtoverlay=pi3-disable-wifi" /boot/config.txt; then
    exit
  else
    sudo sed -i -e :a -e '/^\n*$/ {$d;N;ba' -e '}' /boot/config.txt
    sudo bash -c 'echo -e "dtoverlay=pi3-disable-wifi" >> /boot/config.txt'
  fi

elif [ "$1" == "-enable" ]; then
  if grep -q "^dtoverlay=pi3-disable-wifi" /boot/config.txt; then
    sudo sed -i 's/^dtoverlay=pi3-disable-wifi//' /boot/config.txt
    sudo sed -i -e :a -e '/^\n*$/ {$d;N;ba' -e '}' /boot/config.txt
  fi

fi

exit
