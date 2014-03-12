#!/bin/bash
#----------------------------------------------------------
# Author: coperdli <lhcwhu@gmail.com>
# Date: 2014-3-11
# Purpose: reboot all machine in the cluster
#----------------------------------------------------------

if [ `id -u` -ne 0 ]; then
    echo "you need root privilege to run this program..."
    echo "exiting..."
    exit 1
fi

ssh vslave01 "shutdown -r 0" && echo "vslave01 shuting down... OK"
ssh vslave02 "shutdown -r 0" && echo "vslave02 shuting down... OK"
shutdown -r now

exit 0
