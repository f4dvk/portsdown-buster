#! /bin/bash

sudo apt-get install bc git
sudo wget "https://raw.githubusercontent.com/notro/rpi-source/master/rpi-source" -O /usr/bin/rpi-source
sudo chmod 755 /usr/bin/rpi-source
rpi-source

sudo apt-get install libncurses5-dev

# For rtl8812au
git clone https://github.com/gnab/rtl8812au
cd rtl8812au

# For rtl8812au_rtl8821au
#git clone https://github.com/Grawp/rtl8812au_rtl8821au.git
#cd rtl8812au_rtl8821au

sed -i 's/CONFIG_PLATFORM_I386_PC = y/CONFIG_PLATFORM_I386_PC = n/g' Makefile
sed -i 's/CONFIG_PLATFORM_ARM_RPI = n/CONFIG_PLATFORM_ARM_RPI = y/g' Makefile

# For rtl8812au_rtl8821au
#vi Makefile # comment
#EXTRA_CFLAGS += -Werror=incompatible-pointer-types

make

sudo cp 8812au.ko /lib/modules/`uname -r`/kernel/drivers/net/wireless
sudo depmod -a
sudo modprobe 8812au
