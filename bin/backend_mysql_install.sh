#----------------------------------------------------------------------
#!/bin/bash
# Author: coperdli <lhcwhu@gmail.com>
# Date: 2014-3-7
# Purpose: install mysql to the backend server, and set up the olio user
#       and corresponding databases
#----------------------------------------------------------------------

# change the VALUE of theses variables according to your situation
DBSERVER=192.168.0.233
LOAD_SCALE=30
MYSQL_ROOT_PASSWD="lhcwhu"
mysql_tar_file=mysql-5.*.tar.gz

PDIR=`dirname $0`
logfile=`basename $0 .sh`.log

get_tar_dir() # $1 is the tar file
{
    tar tf $1 | awk -F/ 'NR==1 {print $1}'
}

# give the tar file name, then get the abbreviated file name
get_prog_name() # $1 is the full program name, such as mysql-5.5*
{
    echo $1 | awk -F- '{print $1}'
}

# if mysql server is not installed, install it from the binary package first
if [ "`which mysqld 2>/dev/null`X" = X ]; then
    PREFIX_DIR=/usr/local
    MYSQL_HOME="$PREFIX_DIR/`get_prog_name $mysql_tar_file`"

    if [ $EUID -ne 0 ]; then
        echo "root privilege is needed to execute this program..."
        exit 1
    fi

    tar xzf $mysql_tar_file -C $PREFIX_DIR
    ln -s $PREFIX_DIR/`get_tar_dir $mysql_tar_file` $MYSQL_HOME

    [ "`cat /etc/group | grep mysql`X" == "X" ] && groupadd mysql

    [ "`cat /etc/passwd | grep mysql`X" == "X" ] && useradd -r -g mysql mysql

    chown -R mysql:mysql $MYSQL_HOME/
    cd $MYSQL_HOME
    scripts/mysql_install_db 2>&1>$logfile
    [ $? -ne 0 ] && echo "mysql_install_db failed..."
    chown -R root .
    chown -R mysql data
    cp support-files/my-medium.cnf /etc/my.cnf
    # start mysql server
    yum install -y libaio > /dev/null
    bin/mysqld_safe --user=mysql 2>&1>>$logfile
    [ $? -ne 0 ] && echo "mysql server initial startup failed..."
    # add mysql.server to the /etc/init.d directory
    cp support-files/mysql.server /etc/init.d/mysql.server
    chkconfig --add mysql.server
    chkconfig --level 2345 mysql.server on
    # change the passwd of mysql users
    bin/mysql_secure_installation

    echo "mysql installation all finished...congratulations"
fi

echo "beginning setting the olio related database operations..."
mysql -u root -p $MYSQL_ROOT_PASSWD < $PDIR/mysql_preparation_for_olio.sql
cd $FABAN_HOME/benchmarks/OlioDriver/bin
chmod +x dbloader.sh
./dbloader.sh $DBSERVER $LOAD_SCALE
echo "databases is successfully loaded..."

exit 0
