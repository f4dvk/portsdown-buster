#! /bin/bash

PCONFIGFILE="/home/pi/rpidatv/scripts/portsdown_config.txt"
ACKFILE="/home/pi/rpidatv/scripts/ack_remote.txt"
CMDFILE="/home/pi/tmp/rpi_command.txt"

########################################################################

CLIENTIP=$(cat /var/log/auth.log | grep -a 'Accepted password'| sed -n '$p' | sed 's/^.*from/from/' | awk '{print $2}')
RPI_USER=$(get_config_var rpi_user_remote $PCONFIGFILE)
RPI_PW=$(get_config_var rpi_pw_remote $PCONFIGFILE)

########################################################################

/bin/cat <<EOM >$CMDFILE
 (sshpass -p $RPI_PW ssh -o StrictHostKeyChecking=no $RPI_USER@$CLIENTIP 'bash -s' <<'ENDSSH'

 sed -i '/\(^ack=\).*/s//\1"OK"/' $ACKFILE

ENDSSH
      ) &
EOM

      source "$CMDFILE"

exit
