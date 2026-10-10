#!/bin/bash
E="eth0"
mac_list=(
  "08:00:27:ea:9f:db"
  "02:a7:a1:01:89:bd"
  "02:c8:bf:bf:8d:ff"
)

change_mac() {
    local mac="$1"

    if [[ -z "$mac" ]]; then
        echo "Usage: change_mac <MAC_ADDRESS>"
        return 1
    fi

    echo "New MAC address: $mac"

    # Change the MAC address for eth0
    ip link set eth0 down
    ip link set eth0 address "$mac"
    ip link set eth0 up

}

dhcp_renew() {
	echo "dhcp eth0"
        # Renew DHCP lease
        dhclient -r eth0
	rm /var/lib/dhcp/dhc*
	/bin/sleep 1
        dhclient eth0
	/bin/sleep 1
}

mac=`ip link ls $E | grep ether | awk '{print $2}'` 
echo "current MAC : $mac"

if [ $# -gt 0 ] && [ $1 = 'd' ]; then
	dhcp_renew
elif [ $# -gt 0 ] && [ "$1" = "mac" ]; then
	echo "dhcp mac $E"
        #mac=`ip link ls $E | grep ether | awk '{print $2}'` 
        mac1=`hexdump -n 1 -e '1 "%02x" 1 "\n"' /dev/random`
        #echo $mac
        echo ${mac:0:15}$mac1
        ip link set $E down
        ip link set $E address ${mac:0:15}$mac1
        ip link set $E up

        dhcp_renew
elif [ $# -gt 0 ] && [ "$1" = "rmac" ]; then

        # Generate a random MAC address (keeping the locally administered bit set)
        mac=$(printf '02:%02x:%02x:%02x:%02x:%02x\n' $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)) $((RANDOM%256)))
        
        change_mac $mac
        dhcp_renew
        
elif [ $# -gt 0 ] && [ "$1" = "rmac1" ]; then

        count=${#mac_list[@]}
        # Generate a random index
        index=$((RANDOM % count))

        mac=${mac_list[$index]}
        change_mac $mac
        dhcp_renew

fi
        # Get the newly assigned IP address
        new_ip=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
        echo "New IP address: $new_ip"
        # Check if it's a public IP
        if [[ $new_ip =~ ^(10\.|172\.16\.|192\.168\.) ]]; then
            echo "This is a private IP address."
        else
            echo "This is a public IP address!"
        fi
