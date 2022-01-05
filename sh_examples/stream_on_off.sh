echo "1: Stream Off"
echo "2: Stream On"
read -p "Which step?" STEP


if [ "$STEP" = "1" ]; then
    echo "\nStream Off"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x08 0x00 0x00 0x00
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x08

    echo "\nGet Command Status Value"
    sleep 5
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0x00 0x01 0x01
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0xff
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 7
    sleep 1

elif [ "$STEP" = "2" ]; then
    echo "\nStream On"
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x07 0x00 0x00 0x00
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x07

    echo "\nGet Command Status Value"
    sleep 5
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0x00 0x01 0x01
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 0 0x43 0x05 0xff
    sleep 0.1
    ~/video-app/src/release/sxpfi2c -f0 0 0 0x84 7
    sleep 1

fi
