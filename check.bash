#!/bin/bash

OLD=$(cat /etc/cronsum)
NEW=$(md5sum /etc/crontab | awk '{print $1}')

[ ! -e /etc/crontab ] && exit

if [ ! -e /etc/cronsum ]
then
	echo $NEW > /etc/cronsum
	exit
fi

if [ $OLD != $NEW ]
then
	mail -s "Crontab file has been changed" root@ubuntu < /home/karim/body
fi
