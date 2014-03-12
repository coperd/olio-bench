#!/bin/bash

JAVA_HOME="/usr/lib/jvm/jre-1.7.0-openjdk.x86_64"

PWD=`pwd`
FABAN_HOME="/opt/faban"
OLIO_HOME="/opt/olio"
MYSQL_HOME=
APP_DIR="/var/www/oliophp"
PASSWD="lhcwhu"

# 1 Setting up the Driver
# step 1.1: faban installation
if [ ! -d $FABAN_HOME ]; then
    mkdir $FABAN_HOME
fi
tar xzvf faban*.tar.gz -C $FABAN_HOME
# intial startup
$FABAN_HOME/master/bin/startup.sh
if [ $? -ne 0 ]; then
    echo "faban installation failed, please check the errors!"
    exit $?
fi

# step 1.2: faban services installation
cp $FABAN_HOME/samples/services/ApacheHttpdService/build/ApacheHttpdService.jar services
cp $FABAN_HOME/samples/services/MysqlService/build/MysqlService.jar services
cp $FABAN_HOME/samples/services/MemcachedService/build/MemcachedService.jar services

# step 1.3: copy $OLIO_HOME/OlioDriver.jar to the $FABAN_HOME/benchmarks directory
if [ ! -d $OLIO_HOME ]; then
    mkdir $OLIO_HOME
fi
tar xzvf apache-olio-php*.tar.gz -C $OLIO_HOME

# step 1.4: set the $JAVA_HOME path
export $JAVA_HOME

# step 1.5: start the faban master on the master driver machine
$FABAN_HOME/master/bin/startup.sh

# step 1.6: install JDBC to $FABAN_HOME/benchmarks/OlioDriver/lib
tar xzvf $PWD/mysql-connector-java*.tar.gz -C $FABAN_HOME/benchmarks/OlioDriver/lib

# 2 Installing the Web Application
# step 2.1 software stack installation
yum install -y httpd
yum install -y php
yum install -y mysql
yum install -y memcached

# step 2.2 Application settings up
cp -r $OLIO_HOME/oliophp $APP_DIR/
echo "Edit the httpd.conf used by your system's apache installation. Set the Listen parameter to the
hostname or ip address and set the DocumentRoot to $APP_DIR/public_html. See the httpd.conf file in
$APP_DIR/etc for additional settings."

echo "DO AS TOLD, then press any key to continue..."
read x

echo "See the php.ini provided in $APP_DIR/etc and copy the settings appropriately to the php.ini
for your installation."
echo "DO AS TOLD, then press any key to continue..."
read y

unset x
unset y

# 3 Setting up the Database
#groupadd mysql
#useradd -g mysql -s /usr/bin/bash mysql
#chown -R mysql:mysql $MYSQL_HOME

#su - mysql
#cd bin
#./mysql_install_db
#
#./mysqld_safe –defaults-file=/etc/my.cnf &
#./mysqladmin -u root password $PASSWD
#./mysql -uroot -p$PASSWD
#echo "create user 'olio'@'%' identified by 'olio';"
#echo "grant all privileges on *.* to 'olio'@'%' identified by 'olio' with grant option;"
#echo "create database olio;"
#echo "use olio;"
