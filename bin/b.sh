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
elif [ $# -gt 0 ] && [ "$1" = "rmac" ]; then

        # Generate a random MAC address (keeping the locally administered bit set)
        mac=$(printf '02:%02x:%02x:%02x:%02x:%02x\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
        
        echo "Generated MAC address: $mac"
        
        # Change the MAC address for eth0
        ip link set eth0 down
        ip link set eth0 address $mac
        ip link set eth0 up
        
        # Renew DHCP lease
        dhclient -r eth0
        dhclient eth0
        
        # Get the newly assigned IP address
        new_ip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        
        echo "New IP address: $new_ip"
        
        # Check if it's a public IP
        if [[ $new_ip =~ ^(10\.|172\.16\.|192\.168\.) ]]; then
            echo "This is a private IP address."
        else
            echo "This is a public IP address!"
        fi

fi
