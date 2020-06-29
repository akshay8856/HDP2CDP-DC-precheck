#!/bin/bash

############################################################################################################
#
# Databse version check
# Author: Akshay Mankumbare
# - Premier Support Engineer
# Version: 1
# Date: 11 June 2020
############################################################################################################

now=$1
hms_dbpwd=$4
#protocol=$5
#LOGIN=$6
#PASSWORD=$7
vcheck=$2
#PORT=$9
#BKPDIR=$2/backup
config=$3

hive_database_name=`grep hive_database_name $config | awk -F'=' '{print $2}'`
hms_dbhost=`grep hms_dbhost $config | awk -F'=' '{print $2}'`
hms_dtype=`grep hms_dtype $config | awk -F'=' '{print $2}'`
hmsdb_user=`grep hmsdb_user $config | awk -F'=' '{print $2}'`


if  [ "$hms_dtype" == "mysql" ];then

    echo -e "\e[1m!!!! Checking HiveMetastore Database Version!!!\e[21m"
    hmsraw=`mysql -h $hms_dbhost -u $hmsdb_user -p$hms_dbpwd -e "SELECT VERSION();" |grep "\|"`
    hmsdbv=`echo $hmsraw | awk -F ' ' '{print $2}'`
    echo "HiveMetastore:$hms_dtype:$hmsdbv" >>  $vcheck/files/DB-versioncheck-$now.out
   
elif  [ "$hms_dtype" == "postgresql" ];then

   echo -e "\e[1mChecking HiveMetastore Database Version!!!\e[21m"
   hmsraw=`PGPASSWORD=$hms_dbpwd psql -h $hms_dbhost -U $hmsdb_user -c 'SHOW server_version;'`
   hmsdbv=`echo $kmsraw | awk '{print $3}'`
   echo "HiveMetastore:$hms_dtype:$hmsdbv" >> $vcheck/files/DB-versioncheck-$now.out
   
else 
  echo -e  "Please configured this script with the command to take backup for $hms_dtype \n"

fi
