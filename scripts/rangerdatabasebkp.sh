#!/bin/bash

AMBARIHOST=$1
BKPDIR=$2
now=$3
rangerdbpwd=$4
protocol=$5
LOGIN=$6
PASSWORD=$7

ranger_dbhost=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:8080/api/v1/clusters/c3110/configurations/service_config_versions?service_name=RANGER" | grep -w db_host | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
ranger_dbflavour=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:8080/api/v1/clusters/c3110/configurations/service_config_versions?service_name=RANGER" | grep -w DB_FLAVOR | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

ranger_dbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:8080/api/v1/clusters/c3110/configurations/service_config_versions?service_name=RANGER" | grep -w db_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

ranger_dbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:8080/api/v1/clusters/c3110/configurations/service_config_versions?service_name=RANGER" | grep -w db_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)


if [ "$ranger_dbflavour" == "POSTGRES" ]; then

   echo -e "!!!! Taking Ranger DB backup in $BKPDIR/rangerdbbkpi$now.sql  !!!! \n"
PGPASSWORD=$rangerdbpwd  pg_dump  -h $ranger_dbhost -p 5432 -U $ranger_dbuser  $ranger_dbname > $BKPDIR/rangerdbbkpi$now.sql

elif [ "$ranger_dbflavour" == "MYSQL" ]; then
    echo -e "!!!! Taking Ranger DB backup in $BKPDIR/rangerdbbkpi$now.sql  !!!! \n"
   mysqldump -h $ranger_dbhost -u $ranger_dbuser -p$rangerdbpwd $ranger_dbname > $BKPDIR/rangerdbbkpi$now.sql

else 
  echo -e  "Please configured this script with the command to take backup for $ranger_dbflavour \n"

fi

