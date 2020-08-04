#!/bin/bash

# Updated by davecrump 201911230 for Buster

DisplayUpdateMsg() {
  # Delete any old update message image
  rm /home/pi/tmp/update.jpg >/dev/null 2>/dev/null

  # Create the update image in the tempfs folder
  convert -size 720x576 xc:white \
    -gravity North -pointsize 40 -annotate 0 "\nUpdating Portsdown Software" \
    -gravity Center -pointsize 50 -annotate 0 "$1""\n\nPlease wait" \
    -gravity South -pointsize 50 -annotate 0 "DO NOT TURN POWER OFF" \
    /home/pi/tmp/update.jpg

  # Display the update message on the desktop
  sudo fbi -T 1 -noverbose -a /home/pi/tmp/update.jpg >/dev/null 2>/dev/null
  (sleep 1; sudo killall -9 fbi >/dev/null 2>/dev/null) &  ## kill fbi once it has done its work
}

DisplayRebootMsg() {
  # Delete any old update message image  201802040
  rm /home/pi/tmp/update.jpg >/dev/null 2>/dev/null

  # Create the update image in the tempfs folder
  convert -size 720x576 xc:white \
    -gravity North -pointsize 40 -annotate 0 "\nUpdating Portsdown Software" \
    -gravity Center -pointsize 50 -annotate 0 "$1""\n\nDone" \
    -gravity South -pointsize 50 -annotate 0 "SAFE TO POWER OFF" \
    /home/pi/tmp/update.jpg

  # Display the update message on the desktop
  sudo fbi -T 1 -noverbose -a /home/pi/tmp/update.jpg >/dev/null 2>/dev/null
  (sleep 1; sudo killall -9 fbi >/dev/null 2>/dev/null) &  ## kill fbi once it has done its work
}

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

reset

printf "\nCommencing update.\n\n"

cd /home/pi

## Check which update to load. From M0DNY 201905090
GIT_SRC_FILE=".portsdown_gitsrc"
if [ -e ${GIT_SRC_FILE} ]; then
  GIT_SRC=$(</home/pi/${GIT_SRC_FILE})
else
  GIT_SRC="f4dvk"
fi

## If previous version was Dev (davecrump), load production by default
if [ "$GIT_SRC" == "davecrump" ]; then
  GIT_SRC="f4dvk"
fi

if [ "$1" == "-d" ]; then
  echo "Overriding to update to latest development version"
  GIT_SRC="davecrump"
fi

if [ "$GIT_SRC" == "BritishAmateurTelevisionClub" ]; then
  echo "Updating to latest Production Portsdown build";
elif [ "$GIT_SRC" == "davecrump" ]; then
  echo "Updating to latest development Portsdown build";
else
  echo "Updating to latest ${GIT_SRC} development Portsdown build";
fi

printf "Pausing Streamer or TX if running.\n\n"
sudo killall keyedstream >/dev/null 2>/dev/null
sudo killall keyedtx >/dev/null 2>/dev/null
sudo killall ffmpeg >/dev/null 2>/dev/null

DisplayUpdateMsg "Step 3 of 10\nSaving Current Config\n\nXXX-------"

PATHSCRIPT="/home/pi/rpidatv/scripts"
PATHUBACKUP="/home/pi/user_backups"
PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"

# Note previous version number
cp -f -r /home/pi/rpidatv/scripts/installed_version.txt /home/pi/prev_installed_version.txt

# Create a folder for user configs
mkdir "$PATHUBACKUP" >/dev/null 2>/dev/null

# Make a safe copy of portsdown_config.txtand portsdown_presets
cp -f -r "$PATHSCRIPT"/portsdown_config.txt "$PATHUBACKUP"/portsdown_config.txt

# Make a safe copy of portsdown_presets.txt
cp -f -r "$PATHSCRIPT"/portsdown_presets.txt "$PATHUBACKUP"/portsdown_presets.txt

# Make a safe copy of siggencal.txt
cp -f -r /home/pi/rpidatv/src/siggen/siggencal.txt "$PATHUBACKUP"/siggencal.txt

# Make a safe copy of siggenconfig.txt
cp -f -r /home/pi/rpidatv/src/siggen/siggenconfig.txt "$PATHUBACKUP"/siggenconfig.txt

# Make a safe copy of touchcal.txt
cp -f -r /home/pi/rpidatv/scripts/touchcal.txt "$PATHUBACKUP"/touchcal.txt

# Make a safe copy of rtl-fm_presets.txt
cp -f -r "$PATHSCRIPT"/rtl-fm_presets.txt "$PATHUBACKUP"/rtl-fm_presets.txt

# Make a safe copy of portsdown_locators.txt
cp -f -r "$PATHSCRIPT"/portsdown_locators.txt "$PATHUBACKUP"/portsdown_locators.txt

# Make a safe copy of rx_presets.txt
cp -f -r "$PATHSCRIPT"/rx_presets.txt "$PATHUBACKUP"/rx_presets.txt

# Make a safe copy of the Stream Presets
cp -f -r "$PATHSCRIPT"/stream_presets.txt "$PATHUBACKUP"/stream_presets.txt

# Make a safe copy of the Jetson config
cp -f -r "$PATHSCRIPT"/jetson_config.txt "$PATHUBACKUP"/jetson_config.txt

# Make a safe copy of the LongMynd config
cp -f -r "$PATHSCRIPT"/longmynd_config.txt "$PATHUBACKUP"/longmynd_config.txt

# Make a safe copy of the Lime Calibration frequency or status
cp -f -r "$PATHSCRIPT"/limecalfreq.txt "$PATHUBACKUP"/limecalfreq.txt

cp -f -r "$PATHSCRIPT"/wifi_config.txt "$PATHUBACKUP"/wifi_config.txt
cp -f -r "$PATHSCRIPT"/hotspot_config.txt "$PATHUBACKUP"/hotspot_config.txt

# Make a safe copy of the User Button scripts
cp -f -r "$PATHSCRIPT"/user_button1.sh "$PATHUBACKUP"/user_button1.sh
cp -f -r "$PATHSCRIPT"/user_button2.sh "$PATHUBACKUP"/user_button2.sh
cp -f -r "$PATHSCRIPT"/user_button3.sh "$PATHUBACKUP"/user_button3.sh
cp -f -r "$PATHSCRIPT"/user_button4.sh "$PATHUBACKUP"/user_button4.sh
cp -f -r "$PATHSCRIPT"/user_button5.sh "$PATHUBACKUP"/user_button5.sh

# Make a safe copy of the transmit start and transmit stop scripts
cp -f -r "$PATHSCRIPT"/TXstartextras.sh "$PATHUBACKUP"/TXstartextras.sh
cp -f -r "$PATHSCRIPT"/TXstopextras.sh "$PATHUBACKUP"/TXstopextras.sh

DisplayUpdateMsg "Step 4 of 10\nUpdating Software Packages\n\nXXXX------"

sudo dpkg --configure -a     # Make sure that all the packages are properly configured
sudo apt-get clean           # Clean up the old archived packages
sudo apt-get update          # Update the package list

DisplayUpdateMsg "Step 4a of 10\nStill Updating Software Packages\n\nXXXX------"

# --------- Update Packages ------

sudo apt-get -y dist-upgrade # Upgrade all the installed packages to their latest version

# --------- Install new packages as Required ---------

sudo apt-get -y install mplayer vlc # 202004300 Used for video monitor and LongMynd

# ---------- Update rpidatv -----------

DisplayUpdateMsg "Step 5 of 10\nDownloading Portsdown SW\n\nXXXXX-----"

cd /home/pi

# Download selected source of rpidatv
wget https://github.com/${GIT_SRC}/portsdown-buster/archive/master.zip -O master.zip

# Unzip and overwrite where we need to
unzip -o master.zip
cp -f -r portsdown-buster-master/bin rpidatv
cp -f -r portsdown-buster-master/scripts rpidatv
cp -f -r portsdown-buster-master/src rpidatv
rm -f rpidatv/video/*.jpg
cp -f -r portsdown-buster-master/video rpidatv
cp -f -r portsdown-buster-master/version_history.txt rpidatv/version_history.txt
rm master.zip
rm -rf portsdown-buster-master
cd /home/pi

DisplayUpdateMsg "Step 6 of 10\nCompiling Portsdown SW\n\nXXXXXX----"

# Compile rpidatv core
sudo killall -9 rpidatv
echo "Installing rpidatv"
cd rpidatv/src
touch rpidatv.c
make clean
make
sudo make install

# Compile rpidatv gui
sudo killall -9 rpidatvgui
echo "Installing rpidatvgui"
cd gui
make clean
make
sudo make install

cd /home/pi

# Update limesdr_toolbox
echo "Updating limesdr_toolbox"

sudo rm -r /home/pi/limesdr_toolbox >/dev/null 2>/dev/null
sudo rm -r /home/pi/limesdr_toolbox-master >/dev/null 2>/dev/null

wget https://github.com/f4dvk/limesdr_toolbox/archive/master.zip
unzip master.zip
mv limesdr_toolbox-master limesdr_toolbox
rm master.zip
cd limesdr_toolbox

# Install sub project dvb modulation
# Download and overwrite
wget https://github.com/F5OEO/libdvbmod/archive/master.zip -O master.zip
unzip -o master.zip
cp -f -r libdvbmod-master libdvbmod
rm master.zip
rm -rf libdvbmod-master

# Make libdvbmod
cd libdvbmod/libdvbmod
make
cd ../DvbTsToIQ/
make
cp dvb2iq /home/pi/rpidatv/bin/

#Make limesdr_toolbox
cd /home/pi/limesdr_toolbox/
make
cp limesdr_send /home/pi/rpidatv/bin/
cp limesdr_dump /home/pi/rpidatv/bin/
cp limesdr_stopchannel /home/pi/rpidatv/bin/
cp limesdr_forward /home/pi/rpidatv/bin/
make dvb
cp limesdr_dvb /home/pi/rpidatv/bin/
cd /home/pi

#install adf4351
echo "Installing adf4351"
cd /home/pi/rpidatv/src/adf4351
touch adf4351.c
make
cp adf4351 ../../bin/
cd /home/pi

#install leandvb DVB-S2
cd /home/pi/rpidatv/src/
sudo rm -fr leansdr
wget https://github.com/f4dvk/leansdr/archive/master.zip
unzip master.zip
mv leansdr-master leansdr
rm master.zip
cd leansdr/src/apps
make
cp leandvb ../../../../bin/

# Update the previously selected version of LongMynd
echo
echo "--------------------------------------------"
echo "----- Installing the LongMynd Receiver -----"
echo "--------------------------------------------"
# Remove any old LongMynd installation
cd /home/pi
sudo killall longmynd
sudo rm -rf longmynd

# Download the previously selected version of LongMynd
wget https://github.com/${GIT_SRC}/longmynd/archive/master.zip
unzip -o master.zip
mv longmynd-master longmynd
rm master.zip
cd longmynd
make

#install H264 Decoder : hello_video
#compile ilcomponet first
cd /opt/vc/src/hello_pi/
sudo ./rebuild.sh

# install H264 player
echo "Installing hello_video"
cd /home/pi/rpidatv/src/hello_video
touch video.c
make
cp hello_video.bin ../../bin/

# install MPEG-2 player
echo "Installing hello_video2"
cd /home/pi/rpidatv/src/hello_video2
touch video.c
make
cp hello_video2.bin ../../bin/

# Compile and install the executable for switched repeater streaming (201708150)
echo "Installing switched repeater streaming"
cd /home/pi/rpidatv/src/rptr
make
mv keyedstream /home/pi/rpidatv/bin/
cd /home/pi

# Compile and install the executable for GPIO-switched transmission (201710080)
echo "Installing keyedtx"
cd /home/pi/rpidatv/src/keyedtx
make
sudo mv keyedtx /home/pi/rpidatv/bin/
cd /home/pi

# Compile and install the executable for GPIO-switched transmission with touch (202003020)
cd /home/pi/rpidatv/src/keyedtxtouch
make
mv keyedtxtouch /home/pi/rpidatv/bin/
cd /home/pi

# Compile and install the executable for the Stream Receiver (201807290)
echo "Installing streamrx"
cd /home/pi/rpidatv/src/streamrx
make
mv streamrx /home/pi/rpidatv/bin/
cd /home/pi

# Compile the Signal Generator (201710280)
echo "Installing siggen"
cd /home/pi/rpidatv/src/siggen
make clean
make
sudo make install
cd /home/pi

# Compile the Attenuator Driver (201801060)
echo "Installing atten"
cd /home/pi/rpidatv/src/atten
make
cp /home/pi/rpidatv/src/atten/set_attenuator /home/pi/rpidatv/bin/set_attenuator
cd /home/pi

# Check if raspi2png needs to be installed (202004300)
if [ ! -f "/usr/bin/raspi2png" ]; then
  echo "Installing raspi2png"
  wget https://github.com/AndrewFromMelbourne/raspi2png/archive/master.zip
  unzip master.zip
  mv raspi2png-master raspi2png
  rm master.zip
  cd raspi2png
  make
  sudo make install
  cd /home/pi
fi

# May need to re-copy the other files in /bin here
# Check after publishing!

# There is no step 7!

DisplayUpdateMsg "Step 8 of 10\nRestoring Config\n\nXXXXXXXX--"

# Restore portsdown_config.txt and portsdown_presets.txt
cp -f -r "$PATHUBACKUP"/portsdown_config.txt "$PATHSCRIPT"/portsdown_config.txt
cp -f -r "$PATHUBACKUP"/portsdown_presets.txt "$PATHSCRIPT"/portsdown_presets.txt

 # Restore the user's original siggencal.txt
 cp -f -r "$PATHUBACKUP"/siggencal.txt /home/pi/rpidatv/src/siggen/siggencal.txt

 # Restore the user's original siggenconfig.txt
 cp -f -r "$PATHUBACKUP"/siggenconfig.txt /home/pi/rpidatv/src/siggen/siggenconfig.txt

 # Restore the user's original touchcal.txt
 cp -f -r "$PATHUBACKUP"/touchcal.txt /home/pi/rpidatv/scripts/touchcal.txt

 # Restore the user's rtl-fm_presets.txt
 cp -f -r "$PATHUBACKUP"/rtl-fm_presets.txt "$PATHSCRIPT"/rtl-fm_presets.txt

# Restore the user's original portsdown_locators.txt
cp -f -r "$PATHUBACKUP"/portsdown_locators.txt "$PATHSCRIPT"/portsdown_locators.txt

# Restore the user's original rx_presets.txt
cp -f -r "$PATHUBACKUP"/rx_presets.txt "$PATHSCRIPT"/rx_presets.txt

# Restore the user's original stream presets
cp -f -r "$PATHUBACKUP"/stream_presets.txt "$PATHSCRIPT"/stream_presets.txt

# SSH hostname
sudo rm /home/pi/hostname.txt
cp /home/pi/rpidatv/scripts/configs/hostname.txt /home/pi/hostname.txt

# Restore the user's original Jetson configuration
cp -f -r "$PATHUBACKUP"/jetson_config.txt "$PATHSCRIPT"/jetson_config.txt

# Restore the user's original LongMynd config
cp -f -r "$PATHUBACKUP"/longmynd_config.txt "$PATHSCRIPT"/longmynd_config.txt

# Add LNB Voltage if not included
if ! grep -q lnbvolts "$PATHSCRIPT"/longmynd_config.txt; then
  # File needs updating
  printf "Adding lnbvolts entry to user's longmynd_config.txt\n"
  # Delete any blank lines
  sed -i -e '/^$/d' "$PATHSCRIPT"/longmynd_config.txt
  # Add the new entry and a new line
  echo "lnbvolts=off" >> "$PATHSCRIPT"/longmynd_config.txt
  echo "lnbvolts1=off" >> "$PATHSCRIPT"/longmynd_config.txt
fi

if ! grep -q gain /home/pi/rpidatv/scripts/longmynd_config.txt; then
  printf "Adding gain to user's longmynd_config.txt\n"
  sed -i -e '/^$/d' /home/pi/rpidatv/scripts/longmynd_config.txt
  echo "gain=0" >> /home/pi/rpidatv/scripts/longmynd_config.txt
  echo "" >> /home/pi/rpidatv/scripts/longmynd_config.txt
fi

if ! grep -q scan /home/pi/rpidatv/scripts/longmynd_config.txt; then
  printf "Adding scan to user's longmynd_config.txt\n"
  sed -i -e '/^$/d' /home/pi/rpidatv/scripts/longmynd_config.txt
  echo "scan=50" >> /home/pi/rpidatv/scripts/longmynd_config.txt
  echo "" >> /home/pi/rpidatv/scripts/longmynd_config.txt
fi

if grep -q udpport1 /home/pi/rpidatv/scripts/longmynd_config.txt; then
  printf "Correction to user's longmynd_config.txt\n"
  sed -i 's/^udpport1.*/udpport=1234/' /home/pi/rpidatv/scripts/longmynd_config.txt
fi

cp -f -r "$PATHUBACKUP"/wifi_config.txt "$PATHSCRIPT"/wifi_config.txt
cp -f -r "$PATHUBACKUP"/hotspot_config.txt "$PATHSCRIPT"/hotspot_config.txt

# Restore the user's original Lime Calibration frequency or status
cp -f -r "$PATHUBACKUP"/limecalfreq.txt "$PATHSCRIPT"/limecalfreq.txt

# Restore the user's original User Button scripts
cp -f -r "$PATHUBACKUP"/user_button1.sh "$PATHSCRIPT"/user_button1.sh
cp -f -r "$PATHUBACKUP"/user_button2.sh "$PATHSCRIPT"/user_button2.sh
cp -f -r "$PATHUBACKUP"/user_button3.sh "$PATHSCRIPT"/user_button3.sh
cp -f -r "$PATHUBACKUP"/user_button4.sh "$PATHSCRIPT"/user_button4.sh
cp -f -r "$PATHUBACKUP"/user_button5.sh "$PATHSCRIPT"/user_button5.sh

# Restore the user's original transmit start and transmit stop scripts
cp -f -r "$PATHUBACKUP"/TXstartextras.sh "$PATHSCRIPT"/TXstartextras.sh
cp -f -r "$PATHUBACKUP"/TXstopextras.sh "$PATHSCRIPT"/TXstopextras.sh

# set the framebuffer to 32 bit depth by disabling dtoverlay=vc4-fkms-v3d
echo
echo "----------------------------------------------"
echo "---- Setting Framebuffer to 32 bit depth -----"
echo "----------------------------------------------"

sudo sed -i "/^dtoverlay=vc4-fkms-v3d/c\#dtoverlay=vc4-fkms-v3d" /boot/config.txt

# Install Waveshare 3.5A DTOVERLAY
echo
echo "---------------------------------------------------------"
echo "---- Installing the updated Waveshare 3.5 A Overlay -----"
echo "---------------------------------------------------------"
cd /home/pi/rpidatv/scripts/
sudo cp ./waveshare35a.dtbo /boot/overlays/
cd /home/pi

DisplayUpdateMsg "Step 9 of 10\nFinishing Off\n\nXXXXXXXXX-"

# Update the version number
rm -rf /home/pi/rpidatv/scripts/installed_version.txt
cp /home/pi/rpidatv/scripts/latest_version.txt /home/pi/rpidatv/scripts/installed_version.txt
cp -f -r /home/pi/prev_installed_version.txt /home/pi/rpidatv/scripts/prev_installed_version.txt
rm -rf /home/pi/prev_installed_version.txt

# Save (overwrite) the git source used
echo "${GIT_SRC}" > /home/pi/${GIT_SRC_FILE}

# Réduction temps démarrage sans ethernet
sudo sed -i 's/^TimeoutStartSec.*/TimeoutStartSec=5/' /etc/systemd/system/network-online.target.wants/networking.service
sudo sed -i 's/^#timeout.*/timeout 8;/' /etc/dhcp/dhclient.conf
sudo sed -i 's/^#retry.*/retry 20;/' /etc/dhcp/dhclient.conf

sudo chmod -R 777 /home/pi/rpidatv/scripts/

# Reboot
DisplayRebootMsg "Step 10 of 10\nRebooting\n\nUpdate Complete"
printf "\nRebooting\n"

sleep 1
# Turn off swap to prevent reboot hang
sudo swapoff -a
sudo shutdown -r now  # Seems to be more reliable than reboot

exit
