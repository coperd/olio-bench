#----------------------------------------------------------------------------
#!/bin/bash
# Author: coperdli <lhcwhu@gmail.com>
# Date: 2014-3-11
# Purpose: turn off the unnecessory system services that prevent the test pr-
# ograms from executing properly
#----------------------------------------------------------------------------

# List:
#   @iptables
#   @selinux


# iptables
service iptables stop
chkconfig --level 2345 iptables off

# selinux
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/sysconfig/selinux
echo "selinux has been shutdown, reboot is needed for it to take effect..."
echo "Do you want to reboot now [Y/N]: "
read var
case "$var" in
    Y|y)
    shutdown -r 0 ;;
    N|n)
    ;;
    *)
    echo "you should only type \"Y/y\" or \"N/n\""
    echo "exiting..."
    ;;
esac

exit 0
