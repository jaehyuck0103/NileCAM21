# Description:
#  Capture NileCAM21
#
# Setup:
#sxpf library revision: r4316
#sxpf kernel module revision: r4316
#Found 1 SX proFRAME card in the system:
##0 -> SX proFRAME 3.0 PCIe, CAPTURE card, Firmware version 4.2.5 (Contiguous Buffers)
#      build date 2021-06-23
#      Plasma version 2020-03-10/1
#      max. video channels = 8
#      31 buffers, max. frame size = 16777216
#      I2C capture supported with 31 buffers of size 4096
#      Available bandwidth at slot 6400MByte/s
#      Chip temperature 41.9°C / 107°F
#        port #0 -> SX camAD3 MAX9296A dual (or MAX96716 dual) adapter (type 21), version 1
#                MachXO creation date 2020-02-07/1
#                EEPROM INI data capacity: 1016 bytes
#                EEPROM is blank
#        port #1 -> SX camAD3 MAX9296A dual (or MAX96716 dual) adapter (type 21), version 1
#                MachXO creation date 2020-02-07/1
#                EEPROM INI data capacity: 1016 bytes
#                EEPROM is blank

# load driver with 16MB image buffer
sudo ~/video-app/src/release/load_sxpf.sh framesize=$((0x1000000)) buffers=31

# init camera
~/video-app/src/release/sxpf-init-sequence /dev/sxpf0 -port 0 -ini conf/conf_with_trigger.ini --execute 0
#~/video-app/src/release/sxpf-init-sequence /dev/sxpf0 -port 0 -ini conf/conf.ini --execute 1
#~/video-app/src/release/sxpf-init-sequence /dev/sxpf0 -port 1 -ini conf/conf.ini --execute 0
#~/video-app/src/release/sxpf-init-sequence /dev/sxpf0 -port 1 -ini conf/conf.ini --execute 1

# start record
#~/video-app/src/release/sxpfapp --card 0 --channel 0 -d0x1e -l8 -q -a 100
#~/video-app/src/release/sxpfapp --card 0 --channel 2 -d0x1e -l8 -q
#~/video-app/src/release/sxpfapp --card 0 --channel 4 -d0x1e -l8 -q
#~/video-app/src/release/sxpfapp --card 0 --channel 6 -d0x1e -l8 -q

# Result:
# sxpfapp receives frames
#Tue Nov 16 11:43:54 2021 #109: card=0 ch=0  vs=4161536, 1920x1080, 29.99fps, start=0x00000032f4a3d0b1, end=0x00000032f4b4cd40, sum = 0x00ff00ff


##################
# Change FrameSync #
##################

sleep 5
~/video-app/src/release/sxpfapp --card 0 --channel 0 -d0x1e -l8 -a 100

# Get FrameSync
sleep 1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x11 0x11
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

# Set FrameSync On
sleep 5
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x0b 0x0b
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x11 0x00 0x9a 0x09 0x2b 0x01 0x00 0x00 0x00 0x01 0xa9

# Get Command Status
sleep 5
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0x00 0x01 0x01
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0xff
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 7
sleep 1

# Get FrameSync
sleep 5
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x11 0x11
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13


sleep 5
~/video-app/src/release/sxpfapp --card 0 --channel 0 -d0x1e -l8 -a 100 #-q  #  -a 100
