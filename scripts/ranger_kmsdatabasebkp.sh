#!/bin/bash

AMBARIHOST=$1
BKPDIR=$2
now=$3
ranger_kmsdbpwd=$4
protocol=$5
LOGIN=$6
PASSWORD=$7

ranger_kmsdbhost=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:8080/api/v1/clusters/c3110/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_host | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
ranger_kmsdbflavour=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:8080/api/v1/clusters/c3110/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w DB_FLAVOR | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

ranger_kmsdbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:8080/api/v1/clusters/c3110/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

ranger_kmsdbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:8080/api/v1/clusters/c3110/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)


if [ "$ranger_kmsdbflavour" == "POSTGRES" ]; then

   echo -e "!!!! Taking Ranger DB backup in $BKPDIR/ranger_kmsdbbkpi$now.sql  !!!! \n"
PGPASSWORD=$ranger_kmsdbpwd  pg_dump --no-owner -h $ranger_kmsdbhost -p 5432 -U $ranger_kmsdbuser  $ranger_kmsdbname > $BKPDIR/ranger_kmsdbbkpi$now.sql

elif [ "$ranger_kmsdbflavour" == "MYSQL" ]; then
    echo -e "!!!! Taking Ranger DB backup in $BKPDIR/ranger_kmsdbbkpi$now.sql  !!!! \n"
   mysqldump -h $ranger_kmsdbhost -u $ranger_kmsdbuser -p$ranger_kmsdbpwd $ranger_kmsdbname > $BKPDIR/ranger_kmsdbbkpi$now.sql

else 
  echo -e  "Please configure this script with the command to take backup for $ranger_kmsdbflavour\n"

fi


