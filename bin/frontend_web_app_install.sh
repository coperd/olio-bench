#--------------------------------------------------------------------------------------------
#!/bin/bash
# Author: coperdli <lhcwhu@gmail.com>
# Date: 2014-3-7
# Purpose: to install web server in the frontend server serviced as the Apache Olio frontend
#--------------------------------------------------------------------------------------------

APP_DIR=/var/www/oliophp
logfile=`basename $0 .sh`.log

yum -y install httpd > $logfile
if [ $? -eq 0 ]; then
    service httpd start
    if [ $? -ne 0 ]; then
        echo "Apache server start failed, please check the errors"
        exit
    fi
fi

#yum -y install mysql-server >> lamp_install.log
#if [ $? -eq 0 ]; then
#    service mysqld start 
#fi

#/usr/bin/mysql_secure_installation

yum -y install php php-mysql php-pear php-devel pcre-devel mysql-devel httpd-devel>> $logfile
pecl channel-update pecl.php.net
pecl install apc pdo_mysql memcache
if [ $? -ne 0 ]; then
    echo "php installation failed"
    exit
fi

chkconfig httpd on
#chkconfig mysqld on

yum -y install libevent libmemcached memcached memcached-devel >> $logfile
if [ $? -ne 0 ]; then
    echo "memcached installation failed"
    exit
fi

echo "LAMP installation finished!"

/etc/init.d/httpd restart
chkconfig --add httpd
chkconfig --level 2345 httpd on
/etc/init.d/memcached restart
chkconfig --add memcached
chkconfig --level 2345 memcached on

exit 0
