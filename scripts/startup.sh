#!/bin/bash

# set -x

# This script is sourced from .bashrc at boot and ssh session start
# to sort out driver issues and
# to select the user's selected start-up option.
# Dave Crump 20170721 Revised for Stretch 20180327 and 20190130

############ Set Environment Variables ###############

PATHSCRIPT=/home/pi/rpidatv/scripts
PATHRPI=/home/pi/rpidatv/bin
PATHCONFIGS="/home/pi/rpidatv/scripts/configs"  ## Path to config files
PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"

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

############ Function to Write to Config File ###############

set_config_var() {
lua - "$1" "$2" "$3" <<EOF > "$3.bak"
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
mv "$3.bak" "$3"
}

######################### Start here #####################

if [ "$SESSION_TYPE" == "cron" ]; then
  SESSION_TYPE="boot"
else
  # Determine if this is a user ssh session, or an autoboot
  case $(ps -o comm= -p $PPID) in
    sshd|*/sshd)
      SESSION_TYPE="ssh"
    ;;
    login|sudo)
      SESSION_TYPE="boot"
    ;;
    *)
      SESSION_TYPE="ssh"
    ;;
  esac
fi

# If gui is already running and this is an ssh session
# stop the gui, start the menu and return
ps -cax | grep 'rpidatvgui' >/dev/null 2>/dev/null
RESULT="$?"
if [ "$RESULT" -eq 0 ]; then
  if [ "$SESSION_TYPE" == "ssh" ]; then
    killall rpidatvgui >/dev/null 2>/dev/null
    killall siggen >/dev/null 2>/dev/null
    /home/pi/rpidatv/scripts/menu.sh menu
  fi
  return
fi

# If SigGen is already running and this is an ssh session
# stop the SigGen, start the menu and return
ps -cax | grep 'siggen' >/dev/null 2>/dev/null
RESULT="$?"
if [ "$RESULT" -eq 0 ]; then
  if [ "$SESSION_TYPE" == "ssh" ]; then
    killall rpidatvgui >/dev/null 2>/dev/null
    killall siggen >/dev/null 2>/dev/null
    /home/pi/rpidatv/scripts/menu.sh menu
  fi
  return
fi

# If StreamRX is already running and this is an ssh session
# stop the StreamRX, start the menu and return
ps -cax | grep 'streamrx' >/dev/null 2>/dev/null
RESULT="$?"
if [ "$RESULT" -eq 0 ]; then
  if [ "$SESSION_TYPE" == "ssh" ]; then
    killall streamrx >/dev/null 2>/dev/null
    killall omxplayer.bin >/dev/null 2>/dev/null
    /home/pi/rpidatv/scripts/menu.sh menu
  fi
  return
fi

# If keyedtx is already running and this is an ssh session
# stop the keyedtx, start the menu and return
ps -cax | grep 'keyedtx' >/dev/null 2>/dev/null
RESULT="$?"
if [ "$RESULT" -eq 0 ]; then
  if [ "$SESSION_TYPE" == "ssh" ]; then
    killall keyedtx >/dev/null 2>/dev/null
    killall limesdr_send >den/null 2>/dev/null
    /home/pi/rpidatv/bin/limesdr_stopchannel
    /home/pi/rpidatv/scripts/menu.sh menu
  fi
  return
fi

# If menu is already running, exit to command prompt
ps -cax | grep 'menu.sh' >/dev/null 2>/dev/null
RESULT="$?"
if [ "$RESULT" -eq 0 ]; then
  return
fi

# So continue assuming that this could be a first-start
# or it could be a second ssh session.

# Check user-requested display type
DISPLAY=$(get_config_var display $PCONFIGFILE)

# Read the desired start-up behaviour
MODE_STARTUP=$(get_config_var startup $PCONFIGFILE)

# First check that the correct display has been selected
# to load drivers against the one that is fitted

# But only if it is a boot session and display boot selected

if [[ "$SESSION_TYPE" == "boot" && "$MODE_STARTUP" == "Display_boot" ]]; then

  # Test if the device is a LimeNet Micro
  # (0 for LimeNet Micro detected, 1 for not detected)
  cat /proc/device-tree/model | grep 'Raspberry Pi Compute Module 3' >/dev/null 2>/dev/null
  LIMENET_RESULT="$?"

  # Test which dt-blob.bin is installed (0 for Limenet, else 1)
  ls -l /boot/dt-blob.bin | grep '40874' >/dev/null 2>/dev/null
  LIMENET_DT="$?"

  # Test whether the LimeNet Micro audio fix is installed (0 for installed, 1 for not)
  grep "dtoverlay=pwm-2chan,pin=40,func=4,pin2=41,func2=4" /boot/config.txt >/dev/null 2>/dev/null
  LIMENET_AUDIO="$?"

  if [ "$LIMENET_RESULT" == 0 ] && [ "$LIMENET_DT" == 1 ]; then
    # LimeNET-micro detected, but wrong dt-blob.bin
    sudo cp /home/pi/rpidatv/scripts/configs/dt-blob.bin.lmn /boot/dt-blob.bin
    sudo reboot now
  fi

  if [ "$LIMENET_RESULT" == 1 ] && [ "$LIMENET_DT" == 0 ]; then
    # LimeNET-micro not present, but wrong dt-blob.bin
    sudo cp /home/pi/rpidatv/scripts/configs/dt-blob.bin.norm /boot/dt-blob.bin
    sudo reboot now
  fi

  # Load LimeNET Micro audio fix if required
  if [ "$LIMENET_RESULT" == 0 ] && [ "$LIMENET_AUDIO" == 1 ]; then
    # This section modifies and replaces the end of /boot/config.txt
    # to allow (only) the correct LCD drivers to be loaded at next boot

    # Set constants for the amendment of /boot/config.txt
    lead='^## Begin LCD Driver'               ## Marker for start of inserted text
    tail='^## End LCD Driver'                 ## Marker for end of inserted text
    CHANGEFILE="/boot/config.txt"             ## File requiring added text
    APPENDFILE=$PATHCONFIGS"/lcd_markers.txt" ## File containing both markers
    TRANSFILE=$PATHCONFIGS"/transfer.txt"     ## File used for transfer

    grep -q "$lead" "$CHANGEFILE"     ## Is the first marker already present?
    if [ $? -ne 0 ]; then
      sudo bash -c 'cat '$APPENDFILE' >> '$CHANGEFILE' '  ## If not append the markers
    fi

    # Select the correct driver text
    INSERTFILE=$PATHCONFIGS"/element14_7LMN.txt"

    # Replace whatever is between the markers with the driver text
    sed -e "/$lead/,/$tail/{ /$lead/{p; r $INSERTFILE
	        }; /$tail/p; d }" $CHANGEFILE >> $TRANSFILE

    sudo cp "$TRANSFILE" "$CHANGEFILE"          ## Copy from the transfer file
    rm $TRANSFILE                               ## Delete the transfer file

    sudo reboot now
  fi

  # Test if Waveshare selected, but Element 14 fitted
  if [ "$DISPLAY" == "Waveshare" ]; then

    dmesg | grep 'rpi-ft5406' >/dev/null 2>/dev/null
    SCREEN_RESULT1="$?"
    dmesg | grep 'raspberrypi-ts' >/dev/null 2>/dev/null
    SCREEN_RESULT2="$?"

    if [ "$SCREEN_RESULT1" == 1 ] && [ "$SCREEN_RESULT2" == 1 ]; then # no 7 inch display detected
      # Remove reboot lock
      rm /home/pi/rpidatv/scripts/reboot.lock >/dev/null 2>/dev/null
    else
      # This section modifies and replaces the end of /boot/config.txt
      # to allow (only) the correct LCD drivers to be loaded at next boot

      # Set constants for the amendment of /boot/config.txt
      PATHCONFIGS="/home/pi/rpidatv/scripts/configs"  ## Path to config files
      lead='^## Begin LCD Driver'               ## Marker for start of inserted text
      tail='^## End LCD Driver'                 ## Marker for end of inserted text
      CHANGEFILE="/boot/config.txt"             ## File requiring added text
      APPENDFILE=$PATHCONFIGS"/lcd_markers.txt" ## File containing both markers
      TRANSFILE=$PATHCONFIGS"/transfer.txt"     ## File used for transfer

      grep -q "$lead" "$CHANGEFILE"     ## Is the first marker already present?
      if [ $? -ne 0 ]; then
        sudo bash -c 'cat '$APPENDFILE' >> '$CHANGEFILE' '  ## If not append the markers
      fi

      # Select the correct driver text
      if [ "$LIMENET_RESULT" == 0 ]; then
        INSERTFILE=$PATHCONFIGS"/element14_7LMN.txt"
      else
        INSERTFILE=$PATHCONFIGS"/element14_7.txt"
      fi

      # Replace whatever is between the markers with the driver text
      sed -e "/$lead/,/$tail/{ /$lead/{p; r $INSERTFILE
	        }; /$tail/p; d }" $CHANGEFILE >> $TRANSFILE

      sudo cp "$TRANSFILE" "$CHANGEFILE"          ## Copy from the transfer file
      rm $TRANSFILE                               ## Delete the transfer file

      # Change the Display in the config file
      set_config_var display "Element14_7" $PCONFIGFILE

      # Reboot, but only if reboot lock does not exist
      if [ ! -f /home/pi/rpidatv/scripts/reboot.lock ]; then
        touch /home/pi/rpidatv/scripts/reboot.lock
        sudo reboot now
      fi
    fi
  fi

  # Test if Element 14 selected, but Waveshare fitted

  if [ "$DISPLAY" == "Element14_7" ]; then

    dmesg | grep 'rpi-ft5406' >/dev/null 2>/dev/null
    SCREEN_RESULT1="$?"
    dmesg | grep 'raspberrypi-ts' >/dev/null 2>/dev/null
    SCREEN_RESULT2="$?"

    if [ "$SCREEN_RESULT1" == 0 ] || [ "$SCREEN_RESULT2" == 0 ]; then  # driver present and working
      # Remove reboot lock
      rm /home/pi/rpidatv/scripts/reboot.lock >/dev/null 2>/dev/null
    else
      # This section modifies and replaces the end of /boot/config.txt
      # to allow (only) the correct LCD drivers to be loaded at next boot

      # Set constants for the amendment of /boot/config.txt
      PATHCONFIGS="/home/pi/rpidatv/scripts/configs"  ## Path to config files
      lead='^## Begin LCD Driver'               ## Marker for start of inserted text
      tail='^## End LCD Driver'                 ## Marker for end of inserted text
      CHANGEFILE="/boot/config.txt"             ## File requiring added text
      APPENDFILE=$PATHCONFIGS"/lcd_markers.txt" ## File containing both markers
      TRANSFILE=$PATHCONFIGS"/transfer.txt"     ## File used for transfer

      grep -q "$lead" "$CHANGEFILE"     ## Is the first marker already present?
      if [ $? -ne 0 ]; then
          sudo bash -c 'cat '$APPENDFILE' >> '$CHANGEFILE' '  ## If not append the markers
      fi

      # Select the correct driver text
      INSERTFILE=$PATHCONFIGS"/waveshare.txt"

      # Replace whatever is between the markers with the driver text
      sed -e "/$lead/,/$tail/{ /$lead/{p; r $INSERTFILE
	        }; /$tail/p; d }" $CHANGEFILE >> $TRANSFILE

      sudo cp "$TRANSFILE" "$CHANGEFILE"          ## Copy from the transfer file
      rm $TRANSFILE                               ## Delete the transfer file

      # Change the Display in the config file
      set_config_var display "Waveshare" $PCONFIGFILE

      # Reboot, but only if reboot lock does not exist
      if [ ! -f /home/pi/rpidatv/scripts/reboot.lock ]; then
        touch /home/pi/rpidatv/scripts/reboot.lock
        sudo reboot now
      fi
    fi
  fi
fi

# Test if Waveshare selected, but raspi2raspi set to run
# If so, unset it and reboot
if [ "$DISPLAY" == "Waveshare" ]; then
  if [ -f "/etc/systemd/system/raspi2raspi.service" ]; then
    source /home/pi/rpidatv/scripts/7_inch_comp_vid_off.sh
    sudo reboot now
  fi
fi

# If pi-sdn is not running, check if it is required to run
ps -cax | grep 'pi-sdn' >/dev/null 2>/dev/null
RESULT="$?"
if [ "$RESULT" -ne 0 ]; then
  if [ -f /home/pi/.pi-sdn ]; then
    . /home/pi/.pi-sdn
  fi
fi

# Facility to Disable WiFi
# Calls .wifi_off if present and runs "sudo ip link set wlan0 down"
if [ -f ~/.wifi_off ]; then
    . ~/.wifi_off
fi


# If framebuffer copy is not already running, start it for non-Element 14 displays
if [ "$DISPLAY" != "Element14_7" ]; then
  ps -cax | grep 'fbcp' >/dev/null 2>/dev/null
  RESULT="$?"
  if [ "$RESULT" -ne 0 ]; then
    fbcp &
  fi
fi

# If a boot session, put up the BATC Splash Screen, and then kill the process
sudo fbi -T 1 -noverbose -a /home/pi/rpidatv/scripts/images/BATC_Black.png >/dev/null 2>/dev/null
(sleep 1; sudo killall -9 fbi >/dev/null 2>/dev/null) &  ## kill fbi once it has done its work

# Map the touchscreen event to /dev/input/touchscreen

sudo rm /dev/input/touchscreen >/dev/null 2>/dev/null
cat /proc/bus/input/devices | grep 'H: Handlers=mouse0 event0' >/dev/null 2>/dev/null
RESULT="$?"
if [ "$RESULT" -eq 0 ]; then
  sudo ln /dev/input/event0 /dev/input/touchscreen
fi
cat /proc/bus/input/devices | grep 'H: Handlers=mouse0 event1' >/dev/null 2>/dev/null
RESULT="$?"
if [ "$RESULT" -eq 0 ]; then
  sudo ln /dev/input/event1 /dev/input/touchscreen
fi
cat /proc/bus/input/devices | grep 'H: Handlers=mouse0 event2' >/dev/null 2>/dev/null
RESULT="$?"
if [ "$RESULT" -eq 0 ]; then
  sudo ln /dev/input/event2 /dev/input/touchscreen
fi

# Select the appropriate action

case "$MODE_STARTUP" in
  Prompt)
    # Go straight to command prompt
    return
  ;;
  Console)
    # Start the menu if this is an ssh session
    if [ "$SESSION_TYPE" == "ssh" ]; then
      /home/pi/rpidatv/scripts/menu.sh menu
    fi
    return
  ;;
  TX_boot)
    # Flow will only have got here if menu not already running
    # So start menu in immediate transmit mode
    /home/pi/rpidatv/scripts/menu.sh
    return
  ;;
  Display_boot)
    # Start the Touchscreen Scheduler
    source /home/pi/rpidatv/scripts/scheduler.sh
    return
  ;;
  TestRig_boot)
    # Start the touchscreen interface for the filter-mod test rig
    /home/pi/rpidatv/bin/testrig
    return
  ;;
  Keyed_Stream_boot)
    # Start the Switched stream with the default GPIO Pins
    if [ "$SESSION_TYPE" == "boot" ]; then
      /home/pi/rpidatv/bin/keyedstream 1 7 &
      (/home/pi/rpidatv/scripts/streamer_process_watchdog.sh >/dev/null 2>/dev/null) &
    fi
    return
  ;;
  Cont_Stream_boot)
    # Start a continuous stream
    if [ "$SESSION_TYPE" == "boot" ]; then
      /home/pi/rpidatv/bin/keyedstream 0 &
      (/home/pi/rpidatv/scripts/streamer_process_watchdog.sh >/dev/null 2>/dev/null) &
    fi
    return
  ;;
  Keyed_TX_boot)
    # Start the Switched transmitter with the default GPIO Pins
    if [ "$SESSION_TYPE" == "boot" ]; then
      (sleep 10; /home/pi/rpidatv/bin/keyedtx 1 7) &
    fi
    return
  ;;
  Keyed_TX_Touch_boot)
    # Start the Switched transmitter with the default GPIO Pins and Touchscreen
    if [ "$SESSION_TYPE" == "boot" ]; then
      (sleep 10; /home/pi/rpidatv/bin/keyedtxtouch 1 7) &
    fi
    return
  ;;
  SigGen_boot)
    # Start the Sig Gen with the output on
    if [ "$SESSION_TYPE" == "boot" ]; then
      /home/pi/rpidatv/bin/siggen on
    fi
    return
  ;;
  StreamRX_boot)
    # Start the Streamer Display with the default GPIO Pin
    reset
    if [ "$SESSION_TYPE" == "boot" ]; then
      /home/pi/rpidatv/bin/streamrx &
    fi
    return
  ;;
  Button_tx_boot)
    # Start Button
    if [ "$SESSION_TYPE" == "boot" ]; then
      /home/pi/rpidatv/scripts/rpibutton_tx.sh
    fi
    return
  ;;
  Button_rx_boot)
    # Start Button
    if [ "$SESSION_TYPE" == "boot" ]; then
      /home/pi/rpidatv/scripts/rpibutton_rx.sh
    fi
    return
  ;;
  Button_rx_minitiouner_boot)
    # Start Button
    if [ "$SESSION_TYPE" == "boot" ]; then
      /home/pi/rpidatv/scripts/rpibutton_rx_minitiouner.sh
    fi
    return
  ;;
  Button_rx_lcd_boot)
    # Start Button
    if [ "$SESSION_TYPE" == "boot" ]; then
      /home/pi/rpidatv/scripts/rpibutton_rx_lcd.sh
    fi
    return
  ;;
  *)
    return
  ;;
esac
