#!/bin/bash

cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
# check whether ntpdate is installed already
if [ "`which ntpdate`X" = "X" ]; then
    yum install -y ntpdate 2>&1 > /dev/null
fi
ntpdate us.pool.ntp.org 2>&1 > /dev/null
if [ $? -eq 0 ]; then
    echo "time synchronization OK..."
    echo "DATE: `date`"
else
    echo "cannot synchronize time with server \"us.pool.ntp.org\""
    echo "Please check your network connection..."
fi

exit 0
