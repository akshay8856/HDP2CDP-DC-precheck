#!/bin/bash

############################################################################################################
#
#
# Author: Akshay Mankumbare
# - Premier Support Engineer
# Version: 1
# Date: 11 June 2020
############################################################################################################


############################################################################################################
#
#				******* To confirm if all prerequisites are met *******
#  Do not change the order of the section marked with *******
############################################################################################################

echo -e "\e[35m########################################################\e[0m\n"
echo -e "\e[96mPlease confirm if you have met following prerequisites :\e[0m\n"
echo -e "0. You should have root access on this node"
echo -e "1. Hive Client Must be Installed on this node"
echo -e "2. Password less SSH Must be configured from this node"
echo -e "3. You have Ambari details handy : Username, Password, Host, Port"
echo -e "4. You have ranger database password handby with you"
echo -e "5. You able to login to the ranger database from this node"
echo -e "6. You are able to connect using beeline. Keep JDBC string handy with you"
echo -e "7. You are able to connect to HiveMetastor DB from this node"

while true; do
    read -p $'\e[96mPlease confirm if you have met all above prerequisites (y/n) ? :\e[0m' yn
    case $yn in
        [Yy]* ) echo "Great!!! We are good to go!"; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo -e "\e[35m########################################################\e[0m\n"
############################################################################################################
#
#				*******	Confirming if Required Utilities Are Installed ? *******
#  Do not change the order of the section marked with *******
############################################################################################################
if ! [ -x "$(command -v mysqldump)" ]; then
  echo -e "\e[31mError: mysqldump is not installed.\e[0m"
  echo -e "\e[31mPlease install mysql-community-client package\e[0m"
  exit 1
fi

if ! [ -x "$(command -v pg_dump)" ]; then
  echo -e "\e[31mError: pg_dump is not installed.\e[0m"
  echo -e "\e[31mPlease install postgresql package\e[0m"
  exit 1
fi

if ! [ -x "$(command -v python)" ]; then
  echo -e "\e[31mError: python is not installed.\e[0m"
  exit 1
fi

if ! [ -x "$(command -v perl)" ]; then
  echo -e "\e[31mError: perl is not installed.\e[0m"
  exit 1
fi

if ! [ -x "$(command -v wget)" ]; then
  echo -e "\e[31mError: wget is not installed.\e[0m"
  exit 1
fi
############################################################################################################
#
#				*******	COLLECTING AMBARI DETAILS *******
#  Do not change the order of the section marked with *******
############################################################################################################

echo -en "\e[96mEnter Ambari server host name : \e[0m"
read "ambarihost"
AMBARI_HOST=$ambarihost
echo -en "\e[96mEnter Ambari server port : \e[0m"
read "ambariport"
PORT=$ambariport
#echo -en "\e[96mIs SSL enabled for $AMBARI_HOST (yes/no) : \e[0m"
#read  "ssl"
#SSL=$ssl
echo -en "\e[96mEnter Ambari admin's User Name: \e[0m"
read "username"
echo -en "\e[96mEnter Password for $username : \e[0m"
read -s "pwd"
LOGIN=$username
PASSWORD=$pwd

while true; do
    read -p $'\n\e[96mPlease confirm if you have enabled SSL for Ambari (y/n) ? :\e[0m' yn
    case $yn in
        [Yy]* )  SSL=yes ; break;;
        [Nn]* )  SSL=no ; break;;
        * ) echo "Please answer yes or no.";;
    esac
done
############################################################################################################
#
#				******* SETTING PROTOCOL FOR CURL  *******
# Do not change the order of the section marked with *******
############################################################################################################

if  [ "$SSL" == "no" ];then
 export PROTOCOL=http
else
 export PROTOCOL=https
fi
############################################################################################################
#
# 				*******  CHECKING AMBARI CREDENTIALS *******
# # Do not change the order of the section marked with *******
############################################################################################################
cluster_name=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters" | grep cluster_name | awk -F':' '{print $2}' | awk -F'"' '{print $2}')

if [ -z "$cluster_name" ]
then
      echo -e "\e[31mAmbari details entered are \n AmbariHost: $AMBARI_HOST \n AmbariPort: $PORT \n AdminUser: $LOGIN \n Password: $PASSWORD \e[0m \n"
      echo -e "\e[31mPlease check the Ambari details entered !!!! \e[0m"
   exit
fi
############################################################################################################
#
# 				*******  CREATING DIRECTORY STRUCTURE *******
# Do not change the order of the section marked with *******
############################################################################################################


today="$(date +"%Y%m%d%H%M")"
USER=`whoami`
mkdir -p /HDP2CDP-DC-precheck/files
mkdir -p /HDP2CDP-DC-precheck/review/hive
mkdir -p /HDP2CDP-DC-precheck/review/os
mkdir -p /HDP2CDP-DC-precheck/review/servicecheck
mkdir -p /HDP2CDP-DC-precheck/scripts
mkdir -p /HDP2CDP-DC-precheck/hivechecks
mkdir -p /HDP2CDP-DC-precheck/logs
mkdir -p /HDP2CDP-DC-precheck/backup

INTR=/upgrade
HIVECFG=/upgrade/hivechecks
SCRIPTDIR=/upgrade/scripts
REVIEW=/upgrade/review
LOGDIR=/upgrade/logs
BKP=/upgrade/backup
############################################################################################################
#
# 				 ******* CHECKING THE LIST OF SERVICES IN HDP CLUSTER *******
#  Do not change the order of the section marked with *******
############################################################################################################

echo -e "\n\e[1mCreating a list of services installed in cluster $cluster_name :$INTR/files/services.txt\e[21m"
curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/services?fields=ServiceInfo/service_name" | python -mjson.tool | perl -ne '/"service_name":.*?"(.*?)"/ && print "$1\n"' > $INTR/files/services.txt
echo -e "\e[35m########################################################\e[0m\n"
############################################################################################################
#
#				 *******COLLECTING OTHER REQUIRED DETAILS WHICH CANNOT BE DERIVED FROM API's*******
## Do not change the order of the section marked with *******
############################################################################################################
isranger=`grep -w "RANGER" $INTR/files/services.txt`
israngerkms=`grep -w "RANGER_KMS" $INTR/files/services.txt | tr -s '\n ' ','`

if [ -z "$isranger" ]
then
   :
else
echo -en "\e[96mEnter Password for Ranger Database : \e[0m"
read -s "rpwd"
RANGERPASSWORD=$rpwd
fi


if [ -z "$israngerkms" ]
then
   :
else
echo -e "\n"
echo -en "\e[96mEnter Password for Ranger_KMS Database : \e[0m"
read -s "rkmspwd"
RANGER_KMS_PASSWORD=$rkmspwd
fi

echo -en "\n\n\e[96mPlease enter the password of Hive Metasore Database: \e[0m"
read -s "hmspwd"
hms_dbpwd=$hmspwd

echo -e "\n\e[1mHiveServer2 JDBC URI should be the exact string used to connect using beeline \nFor example: jdbc:hive2://c1110-node4.coelab.cloudera.com:10000/ \e[21m\n "
echo -en "\e[96mPlease enter the JBDC URI for HiveServer2: \e[0m"
read "hs2jdbc"
hs2jdbcuri=$hs2jdbc

############################################################################################################
#
#				 *******  TO CONFIGURE CONFIG.YAML *******
## Do not change the order of the section marked with *******
############################################################################################################

hmsjdbc=$(curl -s -u $LOGIN:$PASSWORD --insecure $PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=HIVE | grep -w "javax.jdo.option.ConnectionURL" -A1 | tail -2 )
hms_jdbc_uri=`echo $hmsjdbc | awk -F ',' '{print $1}' | awk -F '"' '{print $4}' | cut -d? -f1`
hmsdb_user=`echo $hmsjdbc |  awk -F ',' '{print $2}' | awk -F ':' '{print $2}' | awk -F '"' '{print $2}'`
hms_dtype=`echo $hms_jdbc_uri | awk -F ':' '{print $2}'`

# Function to create config.yaml file
create_payload ()
{
echo "metastore_direct:
  uri: \"$1\"
  connectionProperties:
    user: \"$2\"
    password: \"$3\"
  connectionPool:
    min: 3
    max: 5
hs2:
  uri: \"$4\"
  connectionPool:
    min: 3
    max: 5
parallelism: 4
queries:
  db_tbl_count:
    parameters:
      dbs:
        override: \"%\""
} > $HIVECFG/config.yaml

if [ ! -f $HIVECFG/config.yaml ]; then
     echo -e "\e[31mUnable to Find config.yaml ! \e[0m"
     echo -e "\e[1mConfiguring config.yaml for hive table check in $HIVECFG/config.yaml \e[21m \n"
     create_payload  $hms_jdbc_uri $hmsdb_user $hms_dbpwd $hs2jdbcuri
    
fi

if  [ "$hms_dtype" == "mysql" ];then

 	if [ ! -f /usr/share/java/mysql-connector-java.jar ]; then
     	 echo -e "\e[31mUnable to Find Mysql JDBC jar ! \e[0m"
    	 echo -e "\e[1mInstalling Mysql JDBC package\e[21m \n"
    	 yum install mysql-connector-java* -y &> $LOGDIR/hivetablescan-$today.log ; sleep 10 ;cp /usr/share/java/mysql-connector-java.jar $HIVECFG/mysql-connector-java.jar
 	else 
    	 cp /usr/share/java/mysql-connector-java.jar $HIVECFG/mysql-connector-java.jar
 	fi

elif  [ "$hms_dtype" == "postgresql" ];then

  	if [ ! -f /usr/share/java/postgresql-jdbc.jar ]; then
     	 echo -e "\e[31mUnable to Find Postgresql JDBC jar ! \e[0m"
    	 echo -e "\e[1mInstalling Postgresql JDBC package\e[21m \n"
     	 yum install postgresql-jdbc* -y &> $LOGDIR/hivetablescan-$today.log ; sleep 10 ; cp /usr/share/java/postgresql-jdbc.jar $HIVECFG/postgresql-jdbc.jar
    else 
     	 cp /usr/share/java/postgresql-jdbc.jar $HIVECFG/postgresql-jdbc.jar
  	fi
else 
    echo -e "\e[31mPlease configure JDBC jar for $hms_dtype to connect to HiveMetasore\e[0m"
    
fi

if [ ! -f $HIVECFG/hive-sre-shaded.jar ]; then
 echo -e "\e[31m hive-sre-shaded.jar is not available \e[0m"
  echo -e "\e[1m Dwonloading hive-sre-shaded.jar file from : https://github.com/dstreev/cloudera_upgrade_utils/releases \e[21m"
  wget -P $HIVECFG/ https://github.com/dstreev/cloudera_upgrade_utils/releases/download/2.0.4.0-SNAPSHOT/hive-sre-shaded.jar &>/dev/null
fi

echo -e "\e[35m########################################################\e[0m\n"

############################################################################################################
#
# 			********* BACKPUP : Ambari-DB / ambari.properites / ambari-env.sh *******
#
# 1. Password less ssh is must
# 2. works with PGSQL and MYSQL
# 3. Need to test to for mariadb and oracle
# 4. Flow: Backup ambari.properties , ambari-env.sh | Stop Ambari | Backup Database | Start Ambari
# Do not change the order of the section marked with *******
############################################################################################################

echo -e "\e[96mPREREQ - 1. Ambari Backup :\e[0m  \e[1m Ambari Backup and Config\e[21m \n 1. Taking Backup of ambari.properties \n 2. Taking Backup of ambari-env.sh \n 3. Checking if Namenode Service Timeout Is Configured? \n"
sh $SCRIPTDIR/ambaribkp.sh $AMBARI_HOST $BKP $today $REVIEW &> $LOGDIR/ambaribkp-$today.log &

echo -e "Please check the logs at : \e[1m $LOGDIR/ambaribkp-$today.log \e[21m \n"

echo -e "\e[35m########################################################\e[0m\n"
# Need to allow some time for Ambari to start and get heatbeats from all agents.
# Increase time for large clusters
echo -e "\e[1mWaiting for a minute for Ambari to Start & receive heatbeats from all agents\e[21m"
# Increase time for large clusters
sleep 60

############################################################################################################
#
# 						BACKPUP : RANGER-DB
#
# 2. works with PGSQL and MYSQL
# 3. Need to test to for mariadb and oracle
# 3. Need DB password as user input values
############################################################################################################

#isranger=`grep -wi "RANGER" $INTR/files/services.txt | tr -s '\n ' ','`
isranger=${isranger%,}

if [ -z "$isranger" ]
then
echo -e "\n\e[32mRanger Is Not Installed, Skipping Ranger Database Backup\e[0m"
else
echo -e "\n\e[96mPREREQ - 2. Ranger Database \e[0m \e[1mTaking Backup of Ranger DB\e[21m"
sh -x  $SCRIPTDIR/rangerdatabasebkp.sh $AMBARI_HOST $BKP $today $RANGERPASSWORD $PROTOCOL $LOGIN $PASSWORD $REVIEW &> $LOGDIR/rangerdatabasebkp-$today.log &
echo -e "Please check the logs at : \e[1m$LOGDIR/rangerdatabasebkp-$today.log \e[21m  \n"
fi
echo -e "\e[35m########################################################\e[0m\n"

############################################################################################################
#
# 						BACKPUP : RANGER-KMS-DB
#
# 2. works with PGSQL and MYSQL
# 3. Need to test to for mariadb and oracle
# 3. Need DB password as user input values
############################################################################################################

#israngerkms=`grep -wi "RANGER_KMS" $INTR/files/services.txt | tr -s '\n ' ','`
israngerkms=${israngerkms%,}

if [ -z "$israngerkms" ]
then
echo -e "\n\e[32mRanger_KMS Is Not Installed, Skipping Ranger_KMS Database Backup\e[0m"
else
echo -e "\n\e[96mPREREQ - 3. Ranger_KMS Database \e[0m \e[1mTaking Backup of Ranger_KMS DB\e[21m"
sh  $SCRIPTDIR/ranger_kmsdatabasebkp.sh $AMBARI_HOST $BKP $today $RANGER_KMS_PASSWORD $PROTOCOL $LOGIN $PASSWORD $REVIEW &> $LOGDIR/ranger_kms_databasebkp-$today.log &
echo -e "Please check the logs at : \e[1m$LOGDIR/ranger_kms_databasebkp-$today.log \e[21m  \n"
fi
echo -e "\e[35m########################################################\e[0m\n"

############################################################################################################
#
# 					******* CHECKING THE LIST OF SERVICES TO BE REMOVED *******
#  Do not change the order of this section.
# NOTE : This section is depended on output of  "CHECKING THE LIST OF SERVICES IN HDP CLUSTER"
############################################################################################################

echo -e "\e[96mPREREQ - 4. Unsupported Services\e[0m \e[1mServices Installed - to be deleted before upgrade\e[21m"
services=`egrep -i "storm|ACCUMULO|SMARTSENSE|Superset|Flume|Mahout|Falcon|Slider|WebHCat|spark" $INTR/files/services.txt | grep -v -i spark2 | tr -s '\n ' ','`
services=${services%,}

echo -e "\e[31m Below services are installed in cluster $cluster_name and will be deleted as a part of upgrade:\e[0m  \n \e[1m$services\e[21m\n"

echo -e "\n\e[31m- You can plan to remove these services before upgarde\e[0m"
echo -e "\e[31m- Removing Druid and Accumulo services cause data loss\e[0m"
echo -e "\e[31m- Do not proceed with the upgrade to HDP 7.1.1.0 if you want to continue with Druid and Accumulo services.\e[0m"
echo -e "\e[31m- Storm can be replaced with Cloudera Streaming Analytics (CSA) powered by Apache Flink. Contact your Cloudera account team for more information about moving from Storm to CSA\e[0m\n"
echo -e "\e[31m- Flume workloads can be migrated to Cloudera Flow Management (CFM). CFM is a no-code data ingestion and management solution powered by Apache NiFi.\e[0m \n"
echo -e "Below services are installed in cluster $cluster_name and will be deleted as a part of upgrade:  \n $services \n\n * You can plan to remove these services before upgarde \n * Removing the Druid and Accumulo services cause data loss \n * Do not proceed with the upgrade to HDP 7.1.1.0 if you want to continue with Druid and Accumulo services \n * Storm can be replaced with Cloudera Streaming Analytics (CSA) powered by Apache Flink. Contact your Cloudera account team for more information about moving from Storm to CSA \n * Flume workloads can be migrated to Cloudera Flow Management (CFM). CFM is a no-code data ingestion and management solution powered by Apache NiFi\n"  >>  $REVIEW/servicecheck/RemoveServices-$today.out
echo -e "########################################################\n" >>  $REVIEW/servicecheck/RemoveServices-$today.out
echo -e "\e[35m########################################################\e[0m\n"


############################################################################################################
#
# 					******* CHECKING HDF MPACK  *******
#  Do not change the order of this section.
# 1. Need to Add services from HDF stack : Schema Registry | SAM etc ...
# NOTE : This section is depended on output of  "CHECKING THE LIST OF SERVICES IN HDP CLUSTER"
############################################################################################################

echo -e "\e[96mPREREQ - 5. HDF Mpack Check\e[0m \e[1mChecking If Nifi Is Installed?\e[21m\n"
isnifi=`grep -wi "NIFI" $INTR/files/services.txt | tr -s '\n ' ','`
isnifi=${isnifi%,}

if [ -z "$isnifi" ]
then
echo -e "\e[1mNiFi is not installed in cluster $cluster_name\e[21m"
echo -e "\e[1mHDF mpack check completed\e[21m\n"
else
echo -e "\e[31m HDF Mpack is installed in $cluster_name \n Please remove it before upgrade\e[0m"
echo -e "HDF Mpack is installed in $cluster_name \n Please remove it before upgrade" >> $REVIEW/servicecheck/RemoveServices-$today.out
echo -e "\e[1mHDF mpack check completed\e[21m\n"
fi
echo -e "Please check the output at \e[1m$REVIEW/servicecheck/RemoveServices-$today.out\e[21m for the actions to take on components installed in cluster $cluster_name\e[0m \n"
echo -e "\e[35m########################################################\e[0m\n"


############################################################################################################
#
# 					******* CHECKING FOR THIRD PARTY SERVICES *******
#  Do not change the order of this section.
# NOTE : This section is depended on output of  "CHECKING THE LIST OF SERVICES IN HDP CLUSTER"
# ADD MORE SERVICES for example: SR, SAM etc...
############################################################################################################
echo -e "\e[96mPREREQ - 6. Third Party \e[0m \e[1mThird Party Services to be deleted before upgrade\e[21m"

thirdparty=`egrep -vi "AMBARI_INFRA|AMBARI_METRICS|ATLAS|FLUME|HBASE|HDFS|HIVE|KAFKA|MAPREDUCE2|PIG|RANGER|RANGER_KMS|SLIDER|SMARTSENSE|SPARK|SPARK2|SQOOP|TEZ|YARN|ZOOKEEPER|NIFI|KERBEROS|KNOX|ACCUMULO|DRUID|MAHOUT|SUPERSET" $INTR/files/services.txt | grep -v -i spark2 | tr -s '\n ' ','`
thirdparty=${thirdparty%,}

if [ -z "$thirdparty" ];then
echo -e "\e[1mThere are no Third Party Services installed on this cluster $cluster_name\e[21m\n"
else
echo -e "\e[31m Below Third Party services are installed in cluster $cluster_name \nPlease remove this before upgrade:\e[0m \n\e[1m $thirdparty\e[21m"
echo -e "Below Third Party services are installed in cluster $cluster_name \nPlease remove this before  upgrade: \n$thirdparty"  >> $REVIEW/servicecheck/third-party-$today.out
fi
echo -e "\e[35m########################################################\e[0m\n"


############################################################################################################
#
#                     HIVE CHECKS: SCAN ALL HIVE TABLES FROM ALL DATABASES
# 1. Make sure JDBC connection string defined in config.yaml is correct
# 2. Confirm if you can login to HiveMetastore Database from this node.
# 3. Configure JDBC string, username, password for HiveMetastore Database
# 4. User as which this script is running should have all permission in HDFS for all Directories/files
# 5. For non kerberos cluster make sure you have given permission to root user and created home dir for root user.
# # hdfs dfs -setfacl -R -m user:root:rwx /
# NEED TO ADD SUPPORT FOR KERBEROS
############################################################################################################


echo -e "\e[96mPREREQ - 7. HIVE CHECK\e[0m \e[1mRunning Hive table check which includes:\e[21m  \n 1. Hive 3 Upgrade Checks - Locations Scan \n 2. Hive 3 Upgrade Checks - Bad ORC Filenames \n 3. Hive 3 Upgrade Checks - Managed Table Migrations ( Ownership check & Conversion to ACID tables) \n 4. Hive 3 Upgrade Checks - Compaction Check \n 5. Questionable Serde's Check \n 6. Managed Table Shadows \n"
sh $SCRIPTDIR/hiveprereq.sh $INTR/files/hive_databases.txt $HIVECFG  $REVIEW/hive  &> $LOGDIR/hivetablescan-$today.log &
echo -e "Output is available in \e[1m $REVIEW/hive directory \e[21m"
echo -e "Please check the logs at :\e[1m $LOGDIR/hivetablescan-$today.log   \e[21m\n"
echo -e "\e[35m########################################################\e[0m\n"

sleep 5

############################################################################################################
#
# 					CHECKING FOR AUTO RESTART FOR ALL COMPONENTS
#
############################################################################################################

echo -e "\e[96mPREREQ - 8. AUTO RESTART \e[0m \e[1mCheck If Auto Restart Is enabled ?\e[21m "
autorestart=$(curl -s -u $LOGIN:$PASSWORD --insecure $PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/components?fields=ServiceComponentInfo/service_name,ServiceComponentInfo/recovery_enabled | grep -w '"recovery_enabled" : "true"' -B1  -A1 | grep -w '"component_name"' | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tr -s '\n ' ',') 
autorestart=${autorestart%,}

if [ -z "$autorestart" ];then
echo -e "\e[1mAuto Restart is disabled for all the components in $cluster_name\e[21m\n"
else
echo -e "\e[31m Please Disable Auto Restart for Following Components :  \e[0m \n \e[1m$autorestart\e[21m\n"
echo -e "Please Disable Auto Restart for Following Components : \n$autorestart " >> $REVIEW/servicecheck/DisableAutoRestart-$today.out
echo -e "\e[1mOutput is available at $REVIEW/servicecheck/DisableAutoRestart-$today.out \e[21m"
fi
echo -e "\e[35m########################################################\e[0m\n"


############################################################################################################
#
# 					CHECKING THE LIST OF SERVICES TO BE REMOVED
#
# 1. Check OS compatibility on all Nodes : ONLY MAJOR VERSION (limitation because of Ambari API)
# 2. If want to check minor version need to configure a different script
# 3. Will run service checks on all the services installed in cluster.
############################################################################################################


echo -e "\n\e[96mPREREQ - 9. OS & Service Check \e[0m  \e[1mChecking OS compatibility and running service check\e[21m"

sh $SCRIPTDIR/run_all_service_check.sh $AMBARI_HOST $PORT $LOGIN $PASSWORD $REVIEW/os $REVIEW/servicecheck $today $INTR/files/ $PROTOCOL &> $LOGDIR/os-servicecheck-$today.log  &

echo -e "Please check the logs at : \e[1m$LOGDIR/os-servicecheck-$today.log\e[21m\n"

echo -e "\e[35m########################################################\e[0m\n"


