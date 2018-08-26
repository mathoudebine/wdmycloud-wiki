#!/bin/bash
# This script checks for drive state (SMART status OK & temperature between constructor range)
# If drive state is not satisfying, the front panel LED will blink yellow/red
# See README.md for commands description
# Put the script in crontab : sudo crontab -e then add the line "* * * * * /root/check_drive.sh"

max_threshold="65"
min_threshold="0"
temperature=`/usr/sbin/smartctl /dev/sda -A | /bin/grep Temperature_Celsius | /usr/bin/awk '{print $10}'`

echo temperature=$temperature C
echo max_threshold=$max_threshold C
echo min_threshold=$min_threshold C

if [ $temperature \> $max_threshold ];
then 
    echo "Disk is overheating";
    echo yellow > /sys/class/leds/system_led/color
    echo blink > /sys/class/leds/system_led/blink
    echo "["`date`"] Disk temperature=${temperature}C OVERHEAT !" >> /tmp/temperature.log
elif [ $min_threshold \> $temperature ];
then
    echo "Disk is freezing";
    echo yellow > /sys/class/leds/system_led/color
    echo blink > /sys/class/leds/system_led/blink
    echo "["`date`"] Disk temperature=${temperature}C TOO COLD !" >> /tmp/temperature.log
else
    echo "Disk is in recommended temperature range"
    # No led modification for nominal case, to display other system led notifications
fi;


smart_status=`/usr/sbin/smartctl -q silent -a /dev/sda; echo $?`

if [ "$smart_status" = "1" ];
then
    echo "SMART status failed !"
    echo red > /sys/class/leds/system_led/color
    echo blink > /sys/class/leds/system_led/blink
    echo "["`date`"] SMART status failed !" >> /tmp/smart.log
    /usr/sbin/smartctl /dev/sda -H >> /tmp/smart.log
    /usr/sbin/smartctl /dev/sda -A >> /tmp/smart.log
    /usr/sbin/smartctl /dev/sda --log=error >> /tmp/smart.log
    /usr/sbin/smartctl /dev/sda --log=selftest >> /tmp/smart.log
else
    echo "SMART status OK"
    # No led modification for nominal case, to display other system led notifications
fi;