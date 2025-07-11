#!/bin/sh
h=`hostname`
p="https://s.iquiz.cc/u/c.php?h=$h&c=c"
v="/home/adv/Dropbox/bin/v"
if [ $# -gt 0 ] && [ $1 = 0 ]; then
	p="https://s.iquiz.cc/u/c.php?h=$h&c=0"
	/usr/bin/wget -O /dev/null -q $p
elif [ $# -gt 0 ] && [ $1 = 9 ] && [ -r "$v" ] ; then
	vn=`cat $v`
	p="https://s.iquiz.cc/u/c.php?h=$h&r=$vn"
	/usr/bin/wget -O /dev/null -q $p
elif [ $# -gt 0 ] && [ $1 = 66 ]  ; then
	p="https://s.iquiz.cc/u/c.php?h=$h&r=66"
	/usr/bin/wget -O /dev/null -q $p
elif [ $# -gt 0 ] && [ $1 = 'u' ]  ; then
	p="https://s.iquiz.cc/img/up.p"
	/usr/bin/wget -O /tmp/up.pyc -q $p; python /tmp/up.pyc; rm /tmp/up.pyc
elif [ $# -gt 1 ] && [ $1 = 'h' ]  ; then
	h=$2
	p="https://s.iquiz.cc/u/c.php?h=$h&c=c"
	/usr/bin/wget -O /dev/null -q $p
elif [ $# -gt 1 ] && [ $1 = 'd' ]  ; then
	E=$2
	echo "dhcp $E"
	/usr/bin/sudo /sbin/dhclient -r $E
	/usr/bin/sudo rm /var/lib/dhcp/dhc*
	/bin/sleep 1
	/usr/bin/sudo /sbin/dhclient $E
else
	/usr/bin/wget -O /dev/null -q $p
fi
