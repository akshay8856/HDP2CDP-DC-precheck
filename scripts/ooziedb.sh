#!/bin/bash

############################################################################################################
#
# Database backup
# Author: Akshay Mankumbare
# - Premier Support Engineer
# Version: 1
# Date: 11 June 2020
############################################################################################################

AMBARIHOST=$1
CLUSTER=$2
now=$3
ooziepwd=$4
protocol=$5
LOGIN=$6
PASSWORD=$7
PORT=$8
config=$9

#vcheck=$8
#BKPDIR=$8/backup


oozie_dbname=`grep oozie_dbname $config | awk -F'=' '{print $2}'`
oozie_dbhost=`grep oozie_dbhost $config | awk -F'=' '{print $2}'`
oozie_dbflavour=`grep oozie_dbflavour $config | awk -F'=' '{print $2}'`
oozie_dbuser=`grep oozie_dbuser $config | awk -F'=' '{print $2}'`


#ooziejdbcuri=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=OOZIE" |  grep oozie.service.JPAService.jdbc.url | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')


#oozie_dbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=OOZIE" | grep -w oozie.db.schema.name | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
#oozie_dbhost=`echo $ooziejdbcuri | awk -F '/' '{print $3}'`
#oozie_dbflavour=`echo $ooziejdbcuri | awk -F ':' '{print $2}'`
#oozie_dbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=OOZIE" | grep -w oozie.service.JPAService.jdbc.username | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

echo -e "Stoping Oozie Service"
curl -u $LOGIN:$PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop Oozie via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' $protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/services/OOZIE

# This Step is to make sure scripts does not fail because of host key verification
# Will backup the current known_hosts file in /$user-homedir/.ssh/known_hosts.old
# Remove the host key for the specified host from /$useri-home-dir/.ssh/known_hosts.old
ssh-keygen -R $oozie_dbhost

# Will get the latest host key from the specified hosts
ssh-keyscan $oozie_dbhost  >> ~/.ssh/known_hosts


sleep 5

if [ "$oozie_dbflavour" == "postgresql" ]; then

   echo -e "!!!! Taking Oozie DB backup in $BKPDIR/ooziedbbkpi$now.sql  !!!! \n"
 #  PGPASSWORD=$ooziepwd  pg_dump  -h $oozie_dbhost -p 5432 -U $oozie_dbuser  $oozie_dbname > $BKPDIR/ooziedbbkpi$now.sql
  ssh $oozie_dbhost "PGPASSWORD=$ooziepwd  pg_dump  -h $oozie_dbhost -p 5432 -U $oozie_dbuser  $oozie_dbname > ooziedb$now.sql"


 

elif [ "$oozie_dbflavour" == "mysql" ]; then
   echo -e "!!!! Taking Oozie DB backup in $BKPDIR/ooziedbbkpi$now.sql  !!!! \n"
 #  mysqldump -h $oozie_dbhost -u $oozie_dbuser -p$ooziepwd $oozie_dbname > $BKPDIR/ooziedbbkpi$now.sql
  ssh $oozie_dbhost "mysqldump -h $oozie_dbhost -u $oozie_dbuser -p$ooziepwd $oozie_dbname > ooziedb$now.sql"


else
  echo -e  "Please configured this script with the command to take backup for $oozie_dbflavour \n"

fi

sleep 30
echo -e "Starting Oozie Service"
curl -u $LOGIN:$PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start Oozie via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' $protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/services/OOZIE
