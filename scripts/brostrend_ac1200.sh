#! /bin/bash

sudo apt-get -y remove apt-listchanges

sudo dpkg --configure -a
sudo apt-get clean
sudo apt-get update

sudo apt-get -y dist-upgrade

sudo sh -c 'wget deb.trendtechcn.com/installer.sh -O /tmp/installer.sh && sh /tmp/installer.sh'

# Create directory for Autologin link
sudo mkdir -p /etc/systemd/system/getty.target.wants

# Always auto-login
sudo ln -fs /etc/systemd/system/autologin@.service\
 /etc/systemd/system/getty.target.wants/getty@tty1.service

exit
