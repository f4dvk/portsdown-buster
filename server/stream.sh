#!/bin/sh

ffmpeg2 -fflags +nobuffer+flush_packets -flags low_delay -rtbufsize 32 -probesize 32 -y -f alsa -i plug_Loopback_1_2 \
-af aresample=resampler=soxr -acodec pcm_s16le -ar 32000 -ac 1 \
-f s16le -fflags +nobuffer+flush_packets -packetsize 384 -flush_packets 1 -bufsize 960 pipe:1 \
| node /home/pi/rpidatv/server/3las.server.js -port 8080 -samplerate 32000 -channels 1
