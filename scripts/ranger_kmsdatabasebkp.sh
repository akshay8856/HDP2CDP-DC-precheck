#!/bin/bash
############################################################################################################
#
# Databse Backup
# Author: Akshay Mankumbare
# - Premier Support Engineer
# Version: 1
# Date: 11 June 2020
############################################################################################################

AMBARIHOST=$1
CLUSTER=$2
now=$3
ranger_kmsdbpwd=$4
protocol=$5
LOGIN=$6
PASSWORD=$7
PORT=$8
config=$9

#vcheck=$8
#BKPDIR=$8/backup

ranger_kmsdbname=`grep ranger_kmsdbname $config | awk -F'=' '{print $2}'`
ranger_kmsdbhost=`grep ranger_kmsdbhost $config | awk -F'=' '{print $2}'`
ranger_kmsdbflavour=`grep ranger_kmsdbflavour $config | awk -F'=' '{print $2}'`
ranger_kmsdbuser=`grep ranger_kmsdbuser $config | awk -F'=' '{print $2}'`

#ranger_kmsdbhost=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_host | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
#ranger_kmsdbflavour=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w DB_FLAVOR | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
#ranger_kmsdbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
#ranger_kmsdbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

echo -e "Stoping Ranger_KMS Service"
curl -u $LOGIN:$PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop RANGER_KMS via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' $protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/services/RANGER_KMS

# This Step is to make sure scripts does not fail because of host key verification
# Will backup the current known_hosts file in /$user-homedir/.ssh/known_hosts.old
# Remove the host key for the specified host from /$useri-home-dir/.ssh/known_hosts.old
ssh-keygen -R $ranger_kmsdbhost

# Will get the latest host key from the specified hosts
ssh-keyscan $ranger_kmsdbhost  >> ~/.ssh/known_hosts


sleep 5

if [ "$ranger_kmsdbflavour" == "POSTGRES" ]; then

   echo -e "!!!! Taking Ranger_KMS DB backup in Roots Home Directory  !!!! \n"
#   PGPASSWORD=$ranger_kmsdbpwd  pg_dump  -h $ranger_kmsdbhost -p 5432 -U $ranger_kmsdbuser  $ranger_kmsdbname > $BKPDIR/ranger_kmsdbbkpi$now.sql
   ssh $ranger_kmsdbhost "PGPASSWORD=$ranger_kmsdbpwd  pg_dump  -h $ranger_kmsdbhost -p 5432 -U $ranger_kmsdbuser  $ranger_kmsdbname > ranger_kmsdb$now.sql"


elif [ "$ranger_kmsdbflavour" == "MYSQL" ]; then
    echo -e "!!!! Taking Ranger_KMS DB backup in Roots Home Directory  !!!! \n"
#    mysqldump -h $ranger_kmsdbhost -u $ranger_kmsdbuser -p$ranger_kmsdbpwd $ranger_kmsdbname > $BKPDIR/ranger_kmsdbbkpi$now.sql
    ssh $ranger_kmsdbhost "mysqldump -h $ranger_kmsdbhost -u $ranger_kmsdbuser -p$ranger_kmsdbpwd $ranger_kmsdbname > ranger_kmsdb$now.sql"


else
  echo -e  "Please configure this script with the command to take backup for $ranger_kmsdbflavour\n"

fi

sleep 15
echo -e "Starting Ranger_KMS Service"
curl -u $LOGIN:$PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start RANGER_KMS via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' $protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/services/RANGER_KMS
