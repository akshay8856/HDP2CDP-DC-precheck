
#!/bin/bash  
############################################################################################################
#
#  DATABASE BACKUP
# Author: Akshay Mankumbare
# - Premier Support Engineer
# Version: 1
# Date: 11 June 2020
############################################################################################################


AMBARIHOST=$1
CLUSTER=$2
now=$3
rangerdbpwd=$4
protocol=$5
LOGIN=$6
PASSWORD=$7
PORT=$8
config=$9
#vcheck=$8
#BKPDIR=$8/backup

ranger_dbname=`grep ranger_dbname $config | awk -F'=' '{print $2}'`
ranger_dbhost=`grep ranger_dbhost $config | awk -F'=' '{print $2}'`
ranger_dbflavour=`grep ranger_dbflavour $config | awk -F'=' '{print $2}'`
ranger_dbuser=`grep ranger_dbuser $config | awk -F'=' '{print $2}'`

#ranger_dbhost=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER" | grep -w db_host | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
#ranger_dbflavour=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER" | grep -w DB_FLAVOR | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

#ranger_dbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER" | grep -w db_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

#ranger_dbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER" | grep -w db_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

echo -e "Stoping Ranger Service"
curl -u $LOGIN:$PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Stop RANGER via REST"}, "Body": {"ServiceInfo": {"state": "INSTALLED"}}}' $protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/services/RANGER

# This Step is to make sure scripts does not fail because of host key verification
# Will backup the current known_hosts file in /$user-homedir/.ssh/known_hosts.old
# Remove the host key for the specified host from /$useri-home-dir/.ssh/known_hosts.old
ssh-keygen -R $ranger_dbhost

# Will get the latest host key from the specified hosts
ssh-keyscan $ranger_dbhost  >> ~/.ssh/known_hosts


sleep 5

if [ "$ranger_dbflavour" == "POSTGRES" ]; then

   echo -e "!!!! Taking Ranger DB backup in Roots Home Directory  !!!! \n"
#   PGPASSWORD=$rangerdbpwd  pg_dump  -h $ranger_dbhost -p 5432 -U $ranger_dbuser  $ranger_dbname > $BKPDIR/rangerdbbkpi$now.sql
   ssh $ranger_dbhost "PGPASSWORD=$rangerdbpwd  pg_dump -h $ranger_dbhost -p 5432 -U $ranger_dbuser  $ranger_dbname > rangerdbbkpi$now.sql"


elif [ "$ranger_dbflavour" == "MYSQL" ]; then

   echo -e "!!!! Taking Ranger DB backup in Roots Home Directory  !!!! \n"
#    mysqldump -h $ranger_dbhost -u $ranger_dbuser -p$rangerdbpwd $ranger_dbname > $BKPDIR/rangerdbbkpi$now.sql
     ssh $ranger_dbhost "mysqldump -h $ranger_dbhost  -u $ranger_dbuser -p$rangerdbpwd $ranger_dbname > rangerdbbkpi$now.sql"

else
  echo -e  "Please configured this script with the command to take backup for $ranger_dbflavour \n"

fi

sleep 30
echo -e "Starting Ranger Service"
curl -u $LOGIN:$PASSWORD -i -H 'X-Requested-By: ambari' -X PUT -d '{"RequestInfo": {"context" :"Start RANGER via REST"}, "Body": {"ServiceInfo": {"state": "STARTED"}}}' $protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/services/RANGER
