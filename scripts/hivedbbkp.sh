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
hms_dbpwd=$4
protocol=$5
LOGIN=$6
PASSWORD=$7
PORT=$8
config=$9

#vcheck=$8
#BKPDIR=$8/backup

hive_database_name=`grep hive_database_name $config | awk -F'=' '{print $2}'`
hms_dbhost=`grep hms_dbhost $config | awk -F'=' '{print $2}'`
hms_dtype=`grep hms_dtype $config | awk -F'=' '{print $2}'`
hmsdb_user=`grep hmsdb_user $config | awk -F'=' '{print $2}'`


echo -e "Stoping Hive Service"
curl -u $LOGIN:$PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop Hive via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' $protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/services/HIVE

# This Step is to make sure scripts does not fail because of host key verification
# Will backup the current known_hosts file in /$user-homedir/.ssh/known_hosts.old
# Remove the host key for the specified host from /$useri-home-dir/.ssh/known_hosts.old
ssh-keygen -R $hms_dbhost

# Will get the latest host key from the specified hosts
ssh-keyscan $hms_dbhost  >> ~/.ssh/known_hosts

sleep 5

if  [ "$hms_dtype" == "mysql" ];then
   
   echo -e "!!!! Taking Hive DB backup in Root Directory on $hms_dbhost  !!!! \n"
#    mysqldump -h $hms_dbhost -u $hmsdb_user -p$hms_dbpwd $hive_database_name > $INTR/backup/Hivedbbkpi$today.sql
     ssh $hms_dbhost "mysqldump -h $hms_dbhost -u $hmsdb_user -p$hms_dbpwd $hive_database_name > Hivedbbkpi$now.sql"


elif  [ "$hms_dtype" == "postgresql" ];then
   
   echo -e "!!!! Taking Hive DB backup in Root Directory on $hms_dbhost  !!!! \n"
#   PGPASSWORD=$hms_dbpwd  pg_dump -h $hms_dbhost -U $hmsdb_user $hive_database_name > $INTR/backup/Hivedbbkpi$today.sql
    ssh $hms_dbhos "PGPASSWORD=$hms_dbpwd  pg_dump -h $hms_dbhost -U $hmsdb_user $hive_database_name > Hivedbbkpi$now.sql"


else 
  echo -e  "Please configured this script with the command to take backup for $hms_dtype \n"

fi

sleep 30

curl -u $LOGIN:$PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start Hive via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' $protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/services/HIVE

