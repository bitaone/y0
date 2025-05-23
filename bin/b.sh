#!/bin/bash
E="eth0"
if [ $# -gt 1 ] && [ $1 = 'd' ]; then
	E=$2
	echo "dhcp $E"
	/usr/bin/sudo /sbin/dhclient -r $E
	/usr/bin/sudo rm /var/lib/dhcp/dhc*
	/bin/sleep 1
	/usr/bin/sudo /sbin/dhclient $E
elif [ $# -gt 0 ] && [ "$1" = "mac" ]; then
	echo "dhcp mac $E"
        mac=`ip link ls $E | grep ether | awk '{print $2}'` 
        mac1=`hexdump -n 1 -e '1 "%02x" 1 "\n"' /dev/random`
        echo $mac
        echo ${mac:0:15}$mac1
        ip link set $E down
        ip link set $E address ${mac:0:15}$mac1
        ip link set $E up
        dhclient
fi
