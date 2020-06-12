#!/bin/bash

AMBARIHOST=$1
BKPDIR=$2
now=$3
out=$4

echo -e "Taking backup of ambari.properties file at $BKPDIR/ambari.properties \n"
ssh $AMBARIHOST cat /etc/ambari-server/conf/ambari.properties > $BKPDIR/ambari.properties 

echo -e "Taking backup of ambari-env.sh file at $BKPDIR/ambari-env.sh  \n"
ssh $AMBARIHOST cat  /var/lib/ambari-server/ambari-env.sh > $BKPDIR/ambari-env.sh


#server.jdbc.user.passwd=/etc/ambari-server/conf/password.dat
ambaripwdfile=`grep -i server.jdbc.user.passw /tmp/ambari.properties | awk -F'=' '{print $2}'`
ambaridbpwd=`ssh $AMBARIHOST cat $ambaripwdfile`
ambaridbtype=`grep -i server.jdbc.database= /tmp/ambari.properties | awk -F'=' '{print $2}'`
ambariuser=`grep -i server.jdbc.user.name /tmp/ambari.properties | awk -F'=' '{print $2}'`
ambaridb=`grep -i server.jdbc.database_name /tmp/ambari.properties | awk -F'=' '{print $2}'`

echo -e "Checking if upgrade.parameter.nn-restart.timeout is configured in Ambari\n"
echo -e "Checking if upgrade.parameter.nn-restart.timeout is configured in Ambari\n" >> $out/namenode-timeout-$now.out
#echo $ambaripwdfile $ambaripwd $ambaridb $ambariuser
nntimeout=`grep -i upgrade.parameter.nn-restart.timeout $BKPDIR/ambari.properties`
if [ -z "$nntimeout" ];then
echo -e "upgrade.parameter.nn-restart.timeout is NOT configured !!!"
echo -e "For example, record the time (seconds) required to restart the active NameNode for your current Ambari server version.\n If restarting takes 10 minutes, (600 seconds), then add upgrade.parameter.nn-restart.timeout=660 to the /etc/ambari-server/conf/ambari.properties file on the Ambari Server host.\n After adding or resetting the Ambari NameNode restart parameter, restart your Ambari server before starting the HDP upgrade."
echo -e "upgrade.parameter.nn-restart.timeout is NOT configured !!!i \n" >> $out/namenode-timeout-$now.out
echo -e "For example, record the time (seconds) required to restart the active NameNode for your current Ambari server version.\n If restarting takes 10 minutes, (600 seconds), then add upgrade.parameter.nn-restart.timeout=660 to the /etc/ambari-server/conf/ambari.properties file on the Ambari Server host.\n After adding or resetting the Ambari NameNode restart parameter, restart your Ambari server before starting the HDP upgrade." >> $out/namenode-timeout-$now.out
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

elif [ "$ambaridbtype" == "mysql" ]; then
   mysqldump -h $AMBARIHOST -u $ambariuser -p$ambaripwd $ambaridb > $BKPDIR/ambaridbbkpi$now.sql

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
