#--------------------------------------------------------------------------------
#!/bin/bash
# Author: coperd <lhcwhu@gmail.com>
# Date: 2014-3-7
# Purpose: used to install faban on the client, web server and backend server
# Attention: Faban must be installed on all nodes on the same absolute path.
# It has a single master and several agents. The Faban master must run on the 
# client machine. You just need to set up the Faban master and then copy it to 
# the backend and frontend machines, where it will be used as an agent.
#--------------------------------------------------------------------------------

#TODO: write a function to the JDK's installation path automatically
export JAVA_HOME="/usr/lib/jvm/java-1.7.0-openjdk-1.7.0.51.x86_64"

if [ "`grep "JAVA_HOME" /etc/profile`" != "JAVA_HOME=$JAVA_HOME" ]; then
    sed -i '/JAVA_HOME=*/d' /etc/profile
    echo "export JAVA_HOME=$JAVA_HOME" >> /etc/profile
    source /etc/profile
fi

BINDIR=`dirname $0`
if [ -n $BINDIR ]; then
    PDIR=`cd $BINDIR/.. 2>&1>/dev/null && pwd`
    ADIR=$PDIR/applications
    CDIR=$PDIR/conf
fi
# here are some variables that you need to change according to your own situation 
faban_tar_file=faban-kit-*.tar.gz
apache_olio_php_tar_file=apache-olio-php-*.tar.gz
mysql_connector_java_tar_file=mysql-connector-java-*.tar.gz
apache_tomcat_tar_file=apache-tomcat-*.tar.gz

SUFFIX=".sh"
logfile=`basename $0 $SUFFIX`.log
if [ ! -d $PDIR/logs ]; then
    mkdir -p $PDIR/logs
fi
PREFIX_DIR=/opt
MYSQL_HOME=
APP_DIR=/var/www/oliophp
PASSWD=lhcwhu

get_tar_dir() # $1 is the tar.gz file
{
    tar tf $ADIR/$1 | awk -F"/" 'NR==1 {print $1}'
}

# give the tar file name, then get the abbreviated file name
get_prog_name() # $1 is the full program name, such as "faban-kit-latest.tar.gz"
{
    echo $1 | awk -F"-" '{print $1}'
}

# $1 is the variable, $2 is the value of $1
add_to_etc_profile() # $1 is the "variable" needed to add to /etc/profile
{
    if [ -z "`grep $1 /etc/profile`" ]; then
        echo "export $1=$2" >> /etc/profile
        source /etc/profile
    else #TODO: update $1 with $2 if $2 is the new value of $1 variable which is different
         # from the value in /etc/profile
         :
    fi
}

make_soft_link() # $2 --> $1
{
    if [ "$1" != "$2" ]; then
        if [ -f $2 ]; then
            rm -rf $2
        fi
        ln -s $1 $2
    fi
}

get_ip() # $1 is the NIC interface used for faban connection
{
    IP=`ifconfig "$1" | grep 'inet ' | awk -F: '{print $2}' | awk '{print $1}'`
    if [ "$IP"X = X ]; then
        echo "cannot get ip address of interface [$1], make sure that [$1] exists and be up"
        exit $?
    else
        echo $IP
    fi
}

# we want to make $VAR_HOME be the softlink of $VAR_TARDIR if possible
FABAN_HOME=$PREFIX_DIR/faban
FABAN_TARDIR=$PREFIX_DIR/`get_tar_dir $faban_tar_file`
OLIO_HOME=$PREFIX_DIR/olio
OLIO_TARDIR=$PREFIX_DIR/`get_tar_dir $apache_olio_php_tar_file`
JDBC_HOME=$PREFIX_DIR/jdbc
JDBC_TARDIR=$PREFIX_DIR/`get_tar_dir $mysql_connector_java_tar_file`
TOMCAT_HOME=$PREFIX_DIR/tomcat
TOMCAT_TARDIR=$PREFIX_DIR/`get_tar_dir $apache_tomcat_tar_file`

add_to_etc_profile FABAN_HOME $FABAN_HOME
add_to_etc_profile TOMCAT_HOME $TOMCAT_HOME
#add_to_etc_profile OLIO_HOME  $OLIO_HOME
#add_to_etc_profile JDBC_HOME  $JDBC_HOME

# clear the old faban installation, kill the running faban and delete the old files
# port 9980 is the faban http server 
faban_pid=`netstat -ntpl | grep 9980 | awk '{print $7}' | awk -F/ '{print $1}'`
if [ -n "$faban_pid" ]; then
    kill $faban_pid
    echo "killing current faban process[$faban_pid]...Done"
fi
if [ -d $FABAN_HOME ]; then
    rm -rf $FABAN_HOME 
    echo "removing old faban installation files...Done"
fi

# before installation, remove related old files
rm -rf $OLIO_HOME $OLIO_TARDIR $JDBC_HOME $JDBC_TARDIR \
    $TOMCAT_HOME $TOMCAT_TARDIR $FABAN_HOME $FABAN_TARDIR 2>&1>/dev/null
read uu

# step 1.1: faban installation, uncompression is OK!
# we know faban*.tar.gz are compressed to directory of "faban"
tar xzf $ADIR/$faban_tar_file -C $PREFIX_DIR
make_soft_link $FABAN_TARDIR $FABAN_HOME

# step 1.2: faban services installation, for setting up the driver(OlioDriver.jar)
cd $FABAN_HOME
cp samples/services/ApacheHttpdService/build/ApacheHttpdService.jar services
cp samples/services/MysqlService/build/MySQLService.jar services
cp samples/services/MemcachedService/build/MemcachedService.jar services

# extract apache olio tar for later use
tar xzf $ADIR/$apache_olio_php_tar_file -C $PREFIX_DIR
make_soft_link $OLIO_TARDIR $OLIO_HOME

# step 1.3: copy $OLIO_HOME/OlioDriver.jar to the $FABAN_HOME/benchmarks directory
cp $OLIO_HOME/OlioDriver.jar $FABAN_HOME/benchmarks

# step 1.4: set the $JAVA_HOME path, already done before

# step 1.5: start the faban master on the master driver machine, 
# WARNING: this is a must because faban will uncompress benchmarks/*.jar for the first time
$FABAN_HOME/master/bin/startup.sh
if [ $? -ne 0 ]; then
    echo "faban startup failed, please check the errors"
else
    echo "faban startup finished, congratulations"
fi

echo "Please visit the site from the browser first, then press any key to continue..."
read xv
unset xv

tar xzf $ADIR/$mysql_connector_java_tar_file -C $PREFIX_DIR
make_soft_link $JDBC_TARDIR $JDBC_HOME
#mkdir -p $FABAN_HOME/benchmarks/OlioDriver
#cd $FABAN_HOME/benchmarks/OlioDriver
#jar xf ../OlioDriver.jar 

# step 1.6: install JDBC to $FABAN_HOME/benchmarks/OlioDriver/lib
if [ ! -d $FABAN_HOME/benchmarks/OlioDriver/lib ]; then
    mkdir -p $FABAN_HOME/benchmarks/OlioDriver/lib
fi
cp $JDBC_HOME/mysql-connector-java-*.jar $FABAN_HOME/benchmarks/OlioDriver/lib

cd $FABAN_HOME
bin/makeagent #2>&1>/dev/null
faban_client_tar_file=/tmp/faban-agent.tar.gz
ip=`ifconfig eth0 | grep 'inet ' | awk -F: '{print $2}' | awk '{print $1}'`
for node in `cat $CDIR/apache_olio.conf | awk -F= '{print $2}' | grep -v "$ip"`
do
    scp $faban_client_tar_file $node:/tmp/
    ssh $node "tar xzf $faban_client_tar_file -C $PREFIX_DIR; rm -f $faban_client_tar_file; \
        $FABAN_HOME/bin/agent 2>&1>/dev/null && echo \"successfully start up faban agent at $node\""
done
rm -f $faban_client_tar_file
echo "faban agent installation is finished in frontend and backend server"

# setting up the Geocoder Emulator, that's to install geocoder.jar to tomcat server
tar xzf $ADIR/$apache_tomcat_tar_file -C $PREFIX_DIR
make_soft_link $TOMCAT_TARDIR $TOMCAT_HOME

cp $OLIO_HOME/geocoder.war $TOMCAT_HOME/webapps

# startup tomcat server
$TOMCAT_HOME/bin/startup.sh
if [ $? -ne 0 ]; then
    echo "Tomcat startup failed, please check the errors..."
    exit $?
fi

# remove the uncompressed packages that we don't need anymore
rm -rf $OLIO_HOME $JDBC_HOME $OLIO_TARDIR $JDBC_TARDIR

echo "--------------------------------------------------------"
echo "Tomcat running OK..."
echo "Faban server and agent running OK..."
echo "All finished successfully"
echo "--------------------------------------------------------"
