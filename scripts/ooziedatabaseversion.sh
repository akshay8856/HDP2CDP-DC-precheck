#!/bin/bash

############################################################################################################
#
# Databse version check
# Author: Akshay Mankumbare
# - Premier Support Engineer
# Version: 1
# Date: 11 June 2020
############################################################################################################

#AMBARIHOST=$1
#CLUSTER=$2
#now=$3
#ooziepwd=$4
#protocol=$5
#LOGIN=$6
#PASSWORD=$7
#vcheck=$8
#PORT=$9
#BKPDIR=$8/backup


#AMBARIHOST=$1
#CLUSTER=$2
now=$1
ooziepwd=$4
#protocol=$5
#LOGIN=$6
#PASSWORD=$7
vcheck=$2
#PORT=$9
BKPDIR=$2/backup
config=$3

#ooziejdbcuri=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=OOZIE" |  grep oozie.service.JPAService.jdbc.url | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')


#oozie_dbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=OOZIE" | grep -w oozie.db.schema.name | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
#oozie_dbhost=`echo $ooziejdbcuri | awk -F '/' '{print $3}'`
#oozie_dbflavour=`echo $ooziejdbcuri | awk -F ':' '{print $2}'`
#oozie_dbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$CLUSTER/configurations/service_config_versions?service_name=OOZIE" | grep -w oozie.service.JPAService.jdbc.username | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

oozie_dbname=`grep oozie_dbname $config | awk -F'=' '{print $2}'`
oozie_dbhost=`grep oozie_dbhost $config | awk -F'=' '{print $2}'`
oozie_dbflavour=`grep oozie_dbflavour $config | awk -F'=' '{print $2}'`
oozie_dbuser=`grep oozie_dbuser $config | awk -F'=' '{print $2}'`

if [ "$oozie_dbflavour" == "postgresql" ]; then

   echo -e "!!!! Checking Oozie Database Version!!!"
   oozraw=`PGPASSWORD=$ooziepwd psql -h $oozie_dbhost -U $oozie_dbuser -c 'SHOW server_version;'`
   oozdbv=`echo $oozraw | awk '{print $3}'`
   echo "OOZIE:$oozie_dbflavour:$oozdbv" >> $vcheck/files/DB-versioncheck-$now.out

elif [ "$oozie_dbflavour" == "mysql" ]; then
 
   echo -e "!!!! Checking Oozie Database Version!!!"
   oozraw=`mysql -h $oozie_dbhost -u $oozie_dbuser -p$ooziepwd -e "SELECT VERSION();" |grep "\|"`
   oozdbv=`echo $oozraw | awk -F ' ' '{print $2}'`
   echo "OOZIE:$oozie_dbflavour:$oozdbv" >> $vcheck/files/DB-versioncheck-$now.out

else
  echo -e  "Please configured this script with the command to take backup for $oozie_dbflavour \n"

fi
