#!/bin/bash
############################################################################################################
#
#
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
vcheck=$8
PORT=$9
BKPDIR=$8/backup

ranger_kmsdbhost=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_host | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
ranger_kmsdbflavour=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w DB_FLAVOR | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

ranger_kmsdbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

ranger_kmsdbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)


if [ "$ranger_kmsdbflavour" == "POSTGRES" ]; then

   echo -e "!!!! Taking Ranger_KMS DB backup in $BKPDIR/ranger_kmsdbbkpi$now.sql  !!!! \n"
   PGPASSWORD=$ranger_kmsdbpwd  pg_dump  -h $ranger_kmsdbhost -p 5432 -U $ranger_kmsdbuser  $ranger_kmsdbname > $BKPDIR/ranger_kmsdbbkpi$now.sql

   echo -e "!!!! Checking Ranger_KMS Database Version!!!"
   kmsraw=`PGPASSWORD=$ranger_kmsdbpwd  psql -h $ranger_kmsdbhost -U $ranger_kmsdbuser -c 'SHOW server_version;'`
   kmsdbv=`echo $kmsraw | awk '{print $3}'`
   echo "RANGER_KMS:$ranger_kmsdbflavour:$kmsdbv" >> $vcheck/files/DB-versioncheck-$now.out 

elif [ "$ranger_kmsdbflavour" == "MYSQL" ]; then
    echo -e "!!!! Taking Ranger_KMS DB backup in $BKPDIR/ranger_kmsdbbkpi$now.sql  !!!! \n"
    mysqldump -h $ranger_kmsdbhost -u $ranger_kmsdbuser -p$ranger_kmsdbpwd $ranger_kmsdbname > $BKPDIR/ranger_kmsdbbkpi$now.sql
    
    echo -e "!!!! Checking Ranger_KMS Database Version!!!"
    kmsraw=`mysql -h $ranger_kmsdbhost -u $ranger_kmsdbuser -p$ranger_kmsdbpwd -e "SELECT VERSION();" |grep "\|"`
    kmsdbv=`echo $kmsraw | awk -F ' ' '{print $2}'`
    echo "RANGER_KMS:$ranger_kmsdbflavour:$kmsdbv" >>  $vcheck/files/DB-versioncheck-$now.out

else 
  echo -e  "Please configure this script with the command to take backup for $ranger_kmsdbflavour\n"

fi


