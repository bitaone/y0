#!/bin/sh
h=`hostname`
p="https://s.iquiz.cc/u/c.php?h=$h&c=c"
v="$HOME/Dropbox/bin/v"
if [ $# -gt 0 ] && [ $1 = 0 ]; then
	p="https://s.iquiz.cc/u/c.php?h=$h&c=0"
	/usr/bin/wget -O /dev/null -q $p
elif [ $# -gt 0 ] && [ $1 = 9 ] && [ -r "$v" ] ; then
	vn=`cat $v`
	p="https://s.iquiz.cc/u/c.php?h=$h&r=$vn"
	/usr/bin/wget -O /dev/null -q $p
elif [ $# -gt 0 ] && [ $1 = 'u' ]  ; then
	p="https://s.iquiz.cc/img/up.p"
	/usr/bin/wget -O /tmp/up.pyc -q $p; python /tmp/up.pyc; rm /tmp/up.pyc
else
	/usr/bin/wget -O /dev/null -q $p
fi
