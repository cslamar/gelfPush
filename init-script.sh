#!/bin/bash
#
# chkconfig: 35 90 12
# description: gelfPush daemon
#
# Get function from functions library
. /etc/init.d/functions

# Source networking configuration.
. /etc/sysconfig/network

RETVAL=0

prog="gelfPush"
thelock=/var/log/subsys/gelfPush

# Start the service gelfPush
start() {
	[ -f /etc/gelfPush.conf ] || exit 6
	echo -n $"Starting $prog: "
	if [ $UID -ne -0 ]; then
		RETVAL=1
		failure
	else
		daemon /usr/local/sbin/gelfPush
		RETVAL=$?
		[ $RETVAL -eq 0 ] && touch $thelock
	fi;
	echo
	return $RETVAL
}
# Stop the service gelfPush
stop() {
	echo -n $"Stopping $prog: "
	if [ $UID -ne 0 ]; then
		RETVAL=1
		failure
	else
		killproc gelfPush
		RETVAL=$?
		[ $RETVAL -eq 0 ] && rm -f $thelock
	fi;
	echo
	return $RETVAL
}
restart(){
	stop
	start
}
### main logic ###
case "$1" in
	start)
		start
		;;
	stop)
		stop
		;;
	status)
		status gelfPush
		RETVAL=$?
		;;
	restart|reload)
		stop
		start
		;;
	*)
		echo $"Usage: $0 {start|stop|restart|reload|status}"
		exit 1
esac
exit $RETVAL