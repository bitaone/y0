#!/bin/bash
V[0]="A004"
V[1]="V004"
V[2]="A004b"
V[3]="V004b"
V[4]="A004c"
V[5]="A004d"
V[6]="V004b"
V[7]="U004"

E="eth0"

function acpi_off(){
   arr=("$@")
   h=`hostname`
   for v in ${arr[@]}
   do
      echo "acpioff $h $v"
      /usr/bin/VBoxManage controlvm  "$v" acpipowerbutton
   done
}
function power_off(){
   arr=("$@")
   h=`hostname`
   for v in ${arr[@]}
   do
      echo "poweroff $h $v"
      /usr/bin/VBoxManage controlvm  "$v" poweroff 1>&- 2>&- 
   done
}
function power_on(){
   arr=("$@")
   h=`hostname`
   for v in ${arr[@]}
   do
      echo "on $h $v"
      /usr/bin/VBoxHeadless --startvm "$v" 1>&- 2>&- &
   done
}
function power_onmac(){
   arr=("$@")
   h=`hostname`
   for v in ${arr[@]}
   do
      echo "onmac $h $v"
      /usr/bin/VBoxManage modifyvm "$v" --macaddress1 auto
      /usr/bin/VBoxHeadless --startvm "$v" 1>&- 2>&- &
   done
}
function dock_up(){
   arr=("$@")
   h=`hostname | tr '[:upper:]' '[:lower:]'`
   for v in ${arr[@]}
   do
      echo "up $h $v"
      docker compose -f "$h.yml" up -d "$v"
      docker compose -f "${HOME}/Public/${h}.yml" up -d "$v"
      if [[ ${v:0:1} == "A" ]]; then
         echo "docker exec $v"
         docker exec "$v" zjob.sh start
      elif [[ ${v:0:1} == "U" ]]; then
         echo "docker exec $v"
         docker exec "$v" crontab ./ujob
      elif [[ ${v:0:1} == "V" ]]; then
         echo "docker exec $v"
         docker exec "$v" crontab ./vjob
      fi
   done
}
function dock_down(){
   arr=("$@")
   h=`hostname | tr '[:upper:]' '[:lower:]'`
   if [ $# -lt 1 ]; then
      echo "down $h all"
      docker compose -f "${HOME}/Public/${h}.yml" down 
      exit
   fi
   for v in ${arr[@]}
   do
      echo "down $h $v"
      docker compose -f "${HOME}/Public/${h}.yml" down "$v"
   done
}
function dock_pull(){
   containers=($(docker ps -a --format "{{.Names}}"))
   image=$(docker ps --format "{{.Image}}" | head -n 1 )
   dock_down "${containers[@]}"
   echo "docker pull ${image}"
   docker pull "${image}"
   dock_up "${containers[@]}"
   docker image prune
}
function check_connection(){
   if ping -q -c 1 -W 1 8.8.8.8 >/dev/null; then
      echo "IPv4 is up"
      exit
   else
      echo "IPv4 is down"
      acpi_off ${V[@]}
      sleep 50
      /usr/bin/sudo /sbin/reboot
fi

}
s="https://s.iquiz.cc"
#m004,m017 no ssl
v="/home/sin/Public/y0/bin/v"

if [ $# -lt 1 ]; then
   #echo "v : 20190520"
   # + alive b, dhcp rm lease files
   #echo "v : 20220417"
   # + ps
   #echo "v : 20230616"
   #echo "v : 20231108" fix on, onmac no output 
   #echo "v : 20240210 poweroff no output, offon, offonmac"
   #echo "v : 20240404 onmac_post"
   echo "v : 20250523 up down pull dz exec"
   echo "off : off"
   echo "poweroff : poweroff"
   echo "on : on"
   echo "onmac : on + automac"
   echo "onmac_post : on + prefix mac + auto postfix"
   echo "offon: off + on"
   echo "offonmac: off + on + automac"
   echo "dhcp : dhcp"
   echo "ppp : ppp"
   echo "mac: mac"
   echo "mach: mach"
   echo "nameserver: nameserver"
   echo "alive: alive"
   echo "r: r"
   echo "disk: disk"
   echo "u: u"
   echo "update: update"
   echo "pure : pure"
   echo "ping : ping"
   echo "ps: ps"
   echo "log: log"
   exit 1
fi
C=$1
shift

if [ "$C" = "off" ]; then
   OFF=$@
   if [ $# -lt 1 ]; then
      OFF=${V[*]}
   fi
   acpi_off ${OFF[@]}

elif [ "$C" = "poweroff" ]; then
   OFF=$@
   if [ $# -lt 1 ]; then
      OFF=${V[*]}
   fi
   power_off ${OFF[@]}

elif [ "$C" = "on" ]; then
   ON=$@
   power_on ${ON[@]}

elif [ "$C" = "onmac" ]; then
   ON=$@
   power_onmac ${ON[@]}

elif [ "$C" = "onmac_post" ]; then
   v=$1
   mac=$2
   mac1=`date +"%I"`
   echo ${mac:0:15}$mac1
   h=`hostname`
   echo "onmac post $h $v"
   /usr/bin/VBoxManage modifyvm "$v" --macaddress1 ${mac:0:15}$mac1
   /usr/bin/VBoxHeadless --startvm "$v" 1>&- 2>&- &

elif [ "$C" = "offon" ]; then
   OFFON=$@
   acpi_off ${OFFON[@]}

   /bin/sleep 50
   power_off ${OFFON[@]}

   /bin/sleep 2
   power_on ${OFFON[@]}

elif [ "$C" = "offonmac" ]; then
   OFFON=$@
   acpi_off ${OFFON[@]}

   /bin/sleep 35
   power_off ${OFFON[@]}

   /bin/sleep 2
   power_onmac ${OFFON[@]}

elif [ "$C" = "dhcp" ]; then
   if [ $# -gt 0 ]; then
      E=$1
   fi
   echo "dhcp $E"
   /usr/bin/sudo /sbin/dhclient -r $E
   /usr/bin/sudo rm /var/lib/dhcp/dhc*
   /bin/sleep 1
   /usr/bin/sudo /sbin/dhclient $E

elif [ "$C" = "ppp" ]; then
   echo "pppoe reset"
   /usr/bin/sudo poff -a
   /bin/sleep 1
   /usr/bin/sudo pon dsl-provider

elif [ "$C" = "mac" ]; then
   if [ $# -gt 0 ]; then
      E=$1
   fi
   echo "mac $E"
   ip link ls $E
   mac=`ip link ls $E | grep ether | awk '{print $2}'` 
   mac1=`hexdump -n 1 -e '1 "%02x" 1 "\n"' /dev/random`
   echo $mac
   echo ${mac:0:15}$mac1

   #sudo /etc/init.d/networking stop
   sudo ip link set $E down
   sudo ip link set $E address ${mac:0:15}$mac1
   #sudo /etc/init.d/networking start
   sudo ip link set $E up

   ip link ls $E

elif [ "$C" = "mach" ]; then
   if [ $# -gt 0 ]; then
      E=$1
   fi
   echo "mac $E"
   #ip link ls $E
   mac=`ip link ls $E | grep ether | awk '{print $2}'` 
   echo $mac
   mac1=`date +"%I"`
   echo ${mac:0:15}$mac1

   /usr/bin/sudo /sbin/dhclient -r $E
   /bin/sleep 2

   sudo ip link set $E down
   sudo ip link set $E address ${mac:0:15}$mac1
   sudo ip link set $E up

   /bin/sleep 2
   /usr/bin/sudo /sbin/dhclient $E

   check_connection

elif [ "$C" = "nameserver" ]; then
   echo "nameserver 8.8.8.8"
   /usr/bin/sudo /bin/sed -i '1s/^/nameserver 8.8.8.8\n/' /etc/resolv.conf

elif [ "$C" = "u" ]; then
   echo "u"
   h=`hostname`
   V8="${HOME}/Public/y0/bin/m.sh"
   V9="${HOME}/Public/y0/bin/p"
   if [ "$h" = "M007" ]; then
      dock_down "A004"
      /bin/sleep 2
      dock_up "A004"
   fi
   if [ -e "$V8" ]; then
     cp ${V8} "${HOME}/Public/"
     p="$s/u/c.php?h=$h&r=88"
     /usr/bin/wget -O /dev/null -q $p
   elif [ -e "$V9" ]; then
     CURRENT_TIME=$(date +%s)
     MOD_TIME=$(stat -c %Y "$V9")
     # Calculate the time difference
     DIFF=$(( CURRENT_TIME - MOD_TIME ))
     if [ "$DIFF" -le 3600 ]; then
       echo "in 1 hour"
       #dock_pull
       p="$s/u/c.php?h=$h&r=99"
       /usr/bin/wget -O /dev/null -q $p
     fi
   fi
elif [ "$C" = "update" ]; then
   echo "update"
   p="$s/img/m.s"
   /usr/bin/wget -O /tmp/m.sh -q $p 
   mv /tmp/m.sh $HOME/Public/m.sh
   chmod a+x $HOME/Public/m.sh

elif [ "$C" = "alive" ]; then
   h=`hostname`
   if [ $# -gt 0 ]; then
      h=$1
   fi
   p="$s/u/c.php?h=$h&c=c"
   #echo $p
   /usr/bin/wget -O /dev/null -q $p

elif [ "$C" = "r" ]; then
   h=`hostname`
   p="$s/u/c.php?h=$h&r=66"
   #echo $p
   /usr/bin/wget -O /dev/null -q $p

elif [ "$C" = "rv" ]; then
   h=`hostname`
   vn=`cat $v`
   p="$s/u/c.php?h=$h&r=$vn"
   #echo $p
   /usr/bin/wget -O /dev/null -q $p

elif [ "$C" = "rsync" ]; then
   #DEST="sin@59.148.35.54:~/Public/"
   DEST="root@218.252.211.254:/app/"
   V8="${HOME}/Public/y0/bin/v8"
   SRC="${HOME}/Public/y0/log"
   chmod 400 ${V8}
   scp -i "${V8}" -o "StrictHostKeyChecking no" -o "UserKnownHostsFile /dev/null" -r "${SRC}" ${DEST}

elif [ "$C" = "disk" ]; then
   echo "/usr/bin/sudo /bin/dd if=/dev/zero of=/tmp/test1 bs=1G count=1 oflag=dsync"
   /usr/bin/sudo /bin/dd if=/dev/zero of=/tmp/test1 bs=1G count=1 oflag=dsync
   /usr/bin/sudo /bin/rm /tmp/test1 

   echo "benchmark write"
   echo "/usr/bin/sudo /bin/dd if=/dev/zero of=/tmp/test1 bs=1G count=1 oflag=direct"
   /usr/bin/sudo /bin/dd if=/dev/zero of=/tmp/test1 bs=1G count=1 oflag=direct
   echo "benchmark read"
   echo "/usr/bin/sudo /bin/dd if=/tmp/test1 of=/dev/null bs=1G count=1 iflag=direct"
   /usr/bin/sudo /bin/dd if=/tmp/test1 of=/dev/null bs=1G count=1 iflag=direct
   /usr/bin/sudo /bin/rm /tmp/test1 

   echo "benchmark 4K write"
   echo "/usr/bin/sudo /bin/dd if=/dev/zero of=/tmp/test1 bs=4k count=256k oflag=direct"
   /usr/bin/sudo /bin/dd if=/dev/zero of=/tmp/test1 bs=4k count=256k oflag=direct
   echo "benchmark 4K read"
   echo "/usr/bin/sudo /bin/dd if=/tmp/test1 of=/dev/null bs=1G count=1 iflag=direct"
   /usr/bin/sudo /bin/dd if=/tmp/test1 of=/dev/null bs=4k iflag=direct
   /usr/bin/sudo /bin/rm /tmp/test1 

elif [ "$C" = "pure" ]; then
   OFF=${V[*]}
   power_off ${OFF[@]}
   for v in ${OFF[@]}
   do
      echo "del $v"
      /usr/bin/VBoxManage unregistervm "$v" --delete
   done
   /usr/bin/sudo /bin/rm -rf /home/adv/VirtualBox*
   /usr/bin/sudo /bin/rm -rf /home/adv/Public/*
   /usr/bin/sudo /bin/rm -rf /home/sin/VirtualBox*
   /usr/bin/sudo /bin/rm -rf /home/sin/Public/*

elif [ "$C" = "ping" ]; then
   check_connection

elif [ "$C" = "ps" ]; then
   /usr/bin/ps aux | /usr/bin/grep vir

elif [ "$C" = "log" ]; then
   ON=$@
   for v in $ON
   do
      echo "log $v"
      /usr/bin/tail "/home/sin/VirtualBox VMs/$v/Logs/VBox.log"
   done
elif [ "$C" = "pull" ]; then
   cd /home/sin/Public/y0 || exit
   git checkout -- .
   git pull --rebase 
   git reflog expire --all --expire=now
   git gc --aggressive --prune=now

elif [ "$C" = "up" ]; then
   ON=$@
   if [ $# -lt 1 ]; then
      ON=${V[*]}
   fi
   dock_up ${ON[@]}
elif [ "$C" = "down" ]; then
   ON=$@
   dock_down ${ON[@]}
elif [ "$C" = "exec" ]; then
   ON=$@
   echo "exec $@"
   docker exec "$@"
elif [ "$C" = "clog" ]; then
   LOG="/home/sin/Public/y0/log/kws"
   sudo find "$LOG" -type f -name "*.log.*" -mtime +0 -exec rm -f {} \;
elif [ "$C" = "u2" ]; then
   dock_pull
#   for container in $(docker ps -a --format "{{.Names}}"); do
#      dock_down ${container}
#      sleep 2
#      dock_up ${container}
#   done
fi

   # /usr/bin/VBoxManage modifyvm "$v" --nic1 bridged --bridgeadapter1 eth0
   # /usr/bin/VBoxManage modifyvm "$v" --nic1 nat
   # VBoxManage showvminfo A004T | grep MAC
   # VBoxManage clonevm A004T --name POP1 --register
   # VBoxManage unregistervm POP1 --delete
   # VBoxManage modifyvm A004T --natpf1 "cssh,tcp,,4022,,2022"
   # VBoxManage modifyvm A004T --natpf1 delete "cssh"
   # VBoxManage modifyvm A004b8 --name A004b(new name)

#pip install speedtest-cli    https://github.com/sivel/speedtest-cli
#pip install xmltodict        https://github.com/jojo-Hub/huaweiHiLink.git 
#sudo ip r del default via 192.168.8.1 dev enx0c5b8f279a64
