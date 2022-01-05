echo "1: Init Camera"
echo "2: Stream On"
echo "3: Stream Off"
echo "4: DeInit Camera"
echo "5: Stream Config (1080)"
echo "6: Stream Config (480)"
read -p "Which step?" STEP


if [ "$STEP" = "1" ]; then
    echo "\nInit Camera"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x04 0x00 0x00 0x00
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x04
elif [ "$STEP" = "2" ]; then
    echo "\nStream On"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x07 0x00 0x00 0x00
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x07
elif [ "$STEP" = "3" ]; then
    echo "\nStream Off"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x08 0x00 0x00 0x00
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x08
elif [ "$STEP" = "4" ]; then
    echo "\nDeinit Camera"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x06 0x00 0x00 0x00
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x06
elif [ "$STEP" = "5" ]; then
    echo "\nStream Config(1080)"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x09 0x00 0x0e 0x0e
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x09 0x00 0x05 0x59 0x56 0x59 0x55 0x07 0x80 0x04 0x38 0x00 0x1e 0x00 0x01 0xa2
elif [ "$STEP" = "6" ]; then
    echo "\nStream Config(480)"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x09 0x00 0x0e 0x0e
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x09 0x00 0x01 0x59 0x56 0x59 0x55 0x02 0x80 0x01 0xe0 0x00 0x2d 0x00 0x01 0x4d
fi


echo "\nGet Command Status Value"
sleep 5
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0x00 0x01 0x01
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0xff
sleep 0.1
~/video-app/src/release/sxpfi2c -f0 0 0 0x84 7
sleep 1