#!/bin/bash

AMBARIHOST=$1
BKPDIR=$2
now=$3
out=$4
review=$5

# This Stesp is to make sure scripts does not fail because of host key verification
# Will backup the current known_hosts file in /$user-homedir/.ssh/known_hosts.old
# Remove the host key for the specified host from /$useri-home-dir/.ssh/known_hosts.old
ssh-keygen -R $AMBARIHOST

# Will get the latest host key from the specified hosts
ssh-keyscan $AMBARIHOST  >> ~/.ssh/known_hosts

sleep 1

echo -e "Taking backup of ambari.properties file at $BKPDIR/ambari.properties \n"
ssh $AMBARIHOST cat /etc/ambari-server/conf/ambari.properties > $BKPDIR/ambari.properties 

echo -e "Taking backup of ambari-env.sh file at $BKPDIR/ambari-env.sh  \n"
ssh $AMBARIHOST cat  /var/lib/ambari-server/ambari-env.sh > $BKPDIR/ambari-env.sh


#server.jdbc.user.passwd=/etc/ambari-server/conf/password.dat
ambaripwdfile=`grep -i server.jdbc.user.passw $BKPDIR/ambari.properties | awk -F'=' '{print $2}'`
ambaridbpwd=`ssh $AMBARIHOST cat $ambaripwdfile`
ambaridbtype=`grep -i server.jdbc.database= $BKPDIR/ambari.properties | awk -F'=' '{print $2}'`
ambariuser=`grep -i server.jdbc.user.name $BKPDIR/ambari.properties | awk -F'=' '{print $2}'`
ambaridb=`grep -i server.jdbc.database_name $BKPDIR/ambari.properties | awk -F'=' '{print $2}'`

echo -e "Checking if upgrade.parameter.nn-restart.timeout is configured in Ambari\n"
echo -e "Checking if upgrade.parameter.nn-restart.timeout is configured in Ambari\n" >> $review/servicecheck/namenode-timeout-$now.out
#echo $ambaripwdfile $ambaripwd $ambaridb $ambariuser
nntimeout=`grep -i upgrade.parameter.nn-restart.timeout $BKPDIR/ambari.properties`
if [ -z "$nntimeout" ];then
echo -e "upgrade.parameter.nn-restart.timeout is NOT configured !!!\n"

echo -e "* Please ecord the time (seconds) required to restart the active NameNode for your current Ambari server version.\n * If restarting takes 10 minutes, (600 seconds), then add upgrade.parameter.nn-restart.timeout=660 to the /etc/ambari-server/conf/ambari.properties file on the Ambari Server host.\n * After adding or resetting the Ambari NameNode restart parameter, restart your Ambari server before starting the HDP upgrade.\n"

echo -e "upgrade.parameter.nn-restart.timeout is NOT configured !!!i \n" >> $review/servicecheck/namenode-timeout-$now.out
echo -e "* Please record the time (seconds) required to restart the active NameNode for your current Ambari server version.\n * If restarting takes 10 minutes, (600 seconds), then add upgrade.parameter.nn-restart.timeout=660 to the /etc/ambari-server/conf/ambari.properties file on the Ambari Server host.\n * After adding or resetting the Ambari NameNode restart parameter, restart your Ambari server before starting the HDP upgrade.\n" >> $review/servicecheck/namenode-timeout-$now.out
fi


echo -e "!!!! Stopping Ambari Server !!!!\n"
ssh $AMBARIHOST ambari-server stop

if [ $? != 0 ]; then
echo -e "waiting for ambari-server to stop\n"
else
echo -e "ambari server stopped\n"
fi

sleep 2   

if [ "$ambaridbtype" == "postgres" ]; then

   echo -e "!!!! Taking Ambari DB backup in $BKPDIR/ambaridbbkpi$now.sql!!!! \n"
PGPASSWORD=$ambaridbpwd  pg_dump  -h $AMBARIHOST -p 5432 -U $ambariuser  $ambaridb > $BKPDIR/ambaridbbkpi$now.sql

  echo -e "!!!! Checking Ambari Database Version!!!"
  ambraw=`PGPASSWORD=$ambaridbpwd psql -h $AMBARIHOST -U $ambariuser -c 'SHOW server_version;'`
  ambdbv=`echo $ambraw | awk '{print $3}'`
  echo -e "ambari:$ambaridbtype:$ambdbv" >> $out/files/DB-versioncheck-$now.out

elif [ "$ambaridbtype" == "mysql" ]; then
   mysqldump -h $AMBARIHOST -u $ambariuser -p$ambaripwd $ambaridb > $BKPDIR/ambaridbbkpi$now.sql
   echo -e "!!!! Checking Ambari Database Version!!!"
   ambraw=`mysql -h $AMBARIHOST -u $ambariuser -p$ambaripwd -e "SELECT VERSION();" |grep "\|"`
   ambdbv=`echo $ambraw | awk -F ' ' '{print $2}'`
   echo -e "ambari:$ambaridbtype:$ambdbv" >> $out/files/DB-versioncheck-$now.out
  
else 
  echo -e  "Please configured this script with the command to take backup for $ambaridb \n"

fi

sleep 5 

echo -e "!!!! Starting Ambari Server !!!! \n"
ssh $AMBARIHOST ambari-server start

if [ $? != 0 ]; then
echo -e  "waiting for ambari-server to start  \n"
else
echo "ambari server Started "
fi
