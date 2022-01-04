echo "1: Get Value: Auto/Manual Exposure"
echo "2: Set Value: Auto Exposure"
echo "3: Set Value: Manual Exposure"
read -p "Which step?" STEP


if [ "$STEP" = "1" ]; then
    echo "\nGet Auto/Manual Exposure"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x08 0x08
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

elif [ "$STEP" = "2" ]; then

    echo "\nSet Auto Exposure"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x0b 0x0b
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x08 0x00 0x9a 0x09 0x01 0x01 0x00 0x00 0x00 0x00 155

    echo "\nGet Command Status Value"
    sleep 5
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0x00 0x01 0x01
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0xff
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 7
    sleep 1

elif [ "$STEP" = "3" ]; then

    echo "\nSet Manual Exposure"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x0b 0x0b
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x08 0x00 0x9a 0x09 0x01 0x01 0x00 0x00 0x00 0x01 154

    echo "\nGet Command Status Value"
    sleep 5
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0x00 0x01 0x01
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0xff
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 7
    sleep 1
fi
