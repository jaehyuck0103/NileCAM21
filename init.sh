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
~/video-app/src/release/sxpf-init-sequence /dev/sxpf0 -port 0 -ini conf/conf_dual.ini --execute 0
~/video-app/src/release/sxpf-init-sequence /dev/sxpf0 -port 0 -ini conf/conf_dual.ini --execute 1
# ~/video-app/src/release/sxpf-init-sequence /dev/sxpf0 -port 1 -ini conf/conf_dual.ini --execute 0
# ~/video-app/src/release/sxpf-init-sequence /dev/sxpf0 -port 1 -ini conf/conf_dual.ini --execute 0

# ~/video-app/src/release/sxpf-init-sequence /dev/sxpf0 -port 0 -ini conf/conf_with_trigger.ini --execute 0
# ~/video-app/src/release/sxpf-init-sequence /dev/sxpf0 -port 0 -ini conf/conf_with_trigger.ini --execute 1
~/video-app/src/release/sxpf-init-sequence /dev/sxpf0 -port 1 -ini conf/conf_with_trigger.ini --execute 0
# ~/video-app/src/release/sxpf-init-sequence /dev/sxpf0 -port 1 -ini conf/conf_with_trigger.ini --execute 1


# start record
#~/video-app/src/release/sxpfapp --card 0 --channel 0 -d0x1e -l8 -q -a 100
#~/video-app/src/release/sxpfapp --card 0 --channel 2 -d0x1e -l8 -q
#~/video-app/src/release/sxpfapp --card 0 --channel 4 -d0x1e -l8 -q
#~/video-app/src/release/sxpfapp --card 0 --channel 6 -d0x1e -l8 -q

# Internal Trigger (1FPS)
# ~/video-app/src/release/sxpftrigger 0 -c0x1 -f1 -e1 -pH -t cont

# External Trigger
# ~/video-app/src/release/sxpftrigger 0 -c0x1 -t ext
# ~/video-app/src/release/sxpftrigger 0 -f 100 -c0xf -m 10 -t extmul -e 1 -p H
