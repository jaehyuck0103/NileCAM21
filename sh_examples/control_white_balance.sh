echo "1: Get Value: WB"
echo "2: Set Value: WB Manual"
echo "3: Set Value: WB Auto"
read -p "Which step?" STEP


if [ "$STEP" = "1" ]; then
    echo "\nGet WB"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x02 0x02
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x10 0x00 0x05 0x05
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 6
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 13

elif [ "$STEP" = "2" ]; then

    echo "\nSet WB Manual"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x0b 0x0b
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x05 0x00 0x98 0x09 0x0c 0x01 0x00 0x00 0x00 0x00 153

    echo "\nGet Command Status Value"
    sleep 5
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0x00 0x01 0x01
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0xff
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 7
    sleep 1

elif [ "$STEP" = "3" ]; then

    echo "\nSet WB Auto"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x0b 0x0b
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x11 0x00 0x05 0x00 0x98 0x09 0x0c 0x01 0x00 0x00 0x00 0x01 152

    echo "\nGet Command Status Value"
    sleep 5
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0x00 0x01 0x01
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0xff
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 7
    sleep 1
fi
