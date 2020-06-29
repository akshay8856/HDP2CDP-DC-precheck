
#!/bin/bash  
############################################################################################################
#
# Database Version check
# Author: Akshay Mankumbare
# - Premier Support Engineer
# Version: 1
# Date: 11 June 2020
############################################################################################################

#AMBARIHOST=$1
#CLUSTER=$2
now=$1
rangerdbpwd=$4
#protocol=$5
#LOGIN=$6
#PASSWORD=$7
vcheck=$2
#PORT=$9
BKPDIR=$2/backup
config=$3

#ranger_dbhost=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER" | grep -w db_host | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
#ranger_dbflavour=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER" | grep -w DB_FLAVOR | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

#ranger_dbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER" | grep -w db_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

#ranger_dbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=RANGER" | grep -w db_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

ranger_dbname=`grep ranger_dbname $config | awk -F'=' '{print $2}'`
ranger_dbhost=`grep ranger_dbhost $config | awk -F'=' '{print $2}'`
ranger_dbflavour=`grep ranger_dbflavour $config | awk -F'=' '{print $2}'`
ranger_dbuser=`grep ranger_dbuser $config | awk -F'=' '{print $2}'`

if [ "$ranger_dbflavour" == "POSTGRES" ]; then
   echo -e "!!!! Checking Ranger Database Version!!!"
   rangraw=`PGPASSWORD=$rangerdbpwd psql -h $ranger_dbhost -U $ranger_dbuser -c 'SHOW server_version;'`
   rangdbv=`echo $rangraw | awk '{print $3}'`
   echo "RANGER:$ranger_dbflavour:$rangdbv" >> $vcheck/files/DB-versioncheck-$now.out

elif [ "$ranger_dbflavour" == "MYSQL" ]; then

   echo -e "!!!! Checking Ranger Database Version!!!"
   rangraw=`mysql -h $ranger_dbhost -u $ranger_dbuser -p$rangerdbpwd -e "SELECT VERSION();" |grep "\|"`
   rangdbv=`echo $rangraw | awk -F ' ' '{print $2}'`
   echo "RANGER:$ranger_dbflavour:$rangdbv" >> $vcheck/files/DB-versioncheck-$now.out

else
  echo -e  "Please configured this script with the command to take backup for $ranger_dbflavour \n"

fi
