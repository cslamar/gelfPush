#!/bin/bash

/usr/bin/install --mode=0444 -D GelfPush.pm /usr/local/lib64/perl5/GelfPush/GelfPush.pm
/usr/bin/install --mode=0755 init-script.sh /etc/init.d/gelfPush
/usr/bin/install --mode=0700 gelfPush /usr/local/sbin/gelfPush

if [ ! -f /etc/gelfPush.conf ];
then
	/usr/bin/install --mode=744 gelfPush.conf-example /etc/gelfPush.conf
fi
