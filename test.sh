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
# Change Exposure #
##################
sleep 5
~/video-app/src/release/sxpfapp --card 0 --channel 0 -d0x1e -l8 -a 100

# Get AutoExposure
echo "Get Control Value"
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x08 0x08
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

# Set AutoExposure Off
echo "Set Control Value"
sleep 5
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x0b 0x0b
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x08 0x00 0x9a 0x09 0x01 0x01 0x00 0x00 0x00 0x01 154

# Get Command Status
echo "Get Command Status Value"
sleep 5
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0x00 0x01 0x01
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0xff
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 7
sleep 1

# Get AutoExposure
echo "Get Control Value"
sleep 5
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x08 0x08
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13


~/video-app/src/release/sxpfapp --card 0 --channel 0 -d0x1e -l8


echo "Get Brightness"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x00 0x00
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Contrast"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x01 0x01
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Saturation"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get H Flip"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x03 0x03
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get V Flip"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x04 0x04
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get WB"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x05 0x05
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get WB Temp"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x06 0x06
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Sharpness"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x07 0x07
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Auto Exposure"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x08 0x08
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Manual Exposure"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x09 0x09
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Power Line Frequency"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x0a 0x0a
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Gain"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x0b 0x0b
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get HDR"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x0c 0x0c
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get TRIGGER"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x0d 0x0d
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get ROI Window Size"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x0e 0x0e
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get ROI Based Exposure"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x0f 0x0f
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Color Kill"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x10 0x10
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Frame Sync"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x11 0x11
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Lens Correction Mode"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x12 0x12
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get De-Noise"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x13 0x13
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Special Effects"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x14 0x14
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Pan"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x15 0x15
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get Tilt"
sleep 3
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x16 0x16
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

~/video-app/src/release/sxpfapp --card 0 --channel 0 -d0x1e -l8
exit
























































echo "Get Gain"
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x0B 0x0B
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

echo "Get HDR"
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x0C 0x0C
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13


~/video-app/src/release/sxpfapp --card 0 --channel 0 -d0x1e -l8


exit


###########################

# Get ManualExposure
echo "Get Control Value"
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x09 0x09
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

# Set AutoExposure Off
echo "Set Control Value"
sleep 5
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x0b 0x0b
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x09 0x00 0x9a 0x09 0x02 0x01 0x00 0x00 0x00 0xfa 99

# Get Command Status
echo "Get Command Status Value"
sleep 5
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0x00 0x01 0x01
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0xff
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 7
sleep 1

# Get AutoExposure
echo "Get Control Value"
sleep 5
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x09 0x09
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13


~/video-app/src/release/sxpfapp --card 0 --channel 0 -d0x1e -l8 -a 100
