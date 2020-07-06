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
echo -e "1. hdfs yarn mapreduce2 tez hive clients are Installed on this node"
echo -e "2. Configure passwordless SSH access between edge node to Ambari, Zeppelin Master, KDC/Kadmin server & Database server(Ambari, Ranger, RangerKMS, HiveMetastore and Oozie). \nIf passwordless SSH cannot be configured you will have to perform few checks manually.."
echo -e "3. Need Ambari details : Username, Password, Host, Port"
echo -e "4. Need Ranger, RangerKMS, HiveMetastore and Oozie database password"
echo -e "5. Configure access to Ambari, Ranger, RangerKMS, HiveMetastore and Oozie database from this node"
echo -e "6. For unsecured cluster :\n- Create home directory for root user in hdfs\n$ su - hdfs\n$ mkdir /user/root\n$ hdfs dfs -chown root:root /user/root\n- Enable acls for hdfs by configuring dfs.namenode.acls.enabled=true in custom hdfs-site.xml. Restart required services\n-Set acl for root :\n$ hdfs dfs -setfacl -R -m user:root:r-x /\n"
echo -e "7. For secured cluster:\n- Give user readonly permission to all paths in HDFS in Ranger\n- As root user get kerberos ticket for the user for which you created policy\n$ kinit user@realmname\n$ klist"



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
  echo -e "\e[31mPlease install mysql client\e[0m"
  exit 1
fi

if ! [ -x "$(command -v pg_dump)" ]; then
  echo -e "\e[31mError: pg_dump is not installed.\e[0m"
  echo -e "\e[31mPlease install postgresql client\e[0m"
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

if ! [ -x "$(command -v ssh-keygen)" ]; then
  echo -e "\e[31mError: ssh-keygen is not installed.\e[0m"
  exit 1
fi

if ! [ -x "$(command -v ssh-keyscan)" ]; then
  echo -e "\e[31mError: ssh-keyscan is not installed.\e[0m"
  exit 1
fi

if ! [ -x "$(command -v hdfs)" ]; then
  echo -e "\e[31mError: hdfs client is not installed.\e[0m"
  exit 1
fi

if ! [ -x "$(command -v hadoop)" ]; then
  echo -e "\e[31mError: hdfs client is not installed.\e[0m"
  exit 1
fi

############################################################################################################
#
#				*******	COLLECTING AMBARI DETAILS & DATABASE PWD *******
#  Do not change the order of the section marked with *******
############################################################################################################

for i in "$@"
do
case $i in
    -A=*|--ambari=*)
    AMBARI_HOST="${i#*=}"
    shift # past argument=value
    ;;
    -P=*|--port=*)
    PORT="${i#*=}"
    shift # past argument=value
    ;;
    -U=*|--user=*)
    LOGIN="${i#*=}"
    shift # past argument=value
    ;;
    -PWD=*|--password=*)
    PASSWORD="${i#*=}"
    shift # past argument=value
    ;;
    -S=*|--ssl=*)
    SSL="${i#*=}"
    shift # past argument=value
    ;;
    -HMS=*|--hms=*)
    hms_dbpwd="${i#*=}"
    shift # past argument=value
    ;;
    -HS2URI=*|--hs2jdbcuri=*)
    hs2jdbcuri="${i#*=}"
    shift # past argument=value
    ;;
    -RP=*|--ranger_pwd=*)
    RANGERPASSWORD="${i#*=}"
    shift # past argument=value
    ;;
    -RKP=*|--ranger_kms_pwd=*)
    RANGER_KMS_PASSWORD="${i#*=}"
    shift # past argument=value
    ;;
    -OP=*|--oozie_pwd=*)
    OOZIE_PASSWORD="${i#*=}"
    shift # past argument=value
    ;;
    -CDPDC=*|--cdpdc_version=*)
    CDPDC="${i#*=}"
    shift # past argument=value
    ;;
    -PWDSSH=*|--passwordless_ssh=*)
    PWDSSH="${i#*=}"
    shift # past argument=value
    ;;
    -ATP=*|--atlas_pwd=*)
    atlas_pwd="${i#*=}"
    shift # past argument=value
    ;;
    --default)
    DEFAULT=YES
    shift # past argument with no value
    ;;
    *)
          # unknown option
    ;;
esac
done


############################################################################
#    CHECKING IF CDP DC VERSION IS PASSED
############################################################################

if [ -z "$CDPDC" ]
then
      echo -e "\e[31mError: Please mention the CDP-DC version by passing -CDPDC or --cdpdc_version\e[0m"
       exit 1
else
  :
fi

############################################################################

#echo -en "\e[96mEnter Ambari server host name : \e[0m"
#read "ambarihost"
#AMBARI_HOST=$ambarihost
#echo -en "\e[96mEnter Ambari server port : \e[0m"
#read "ambariport"
#PORT=$ambariport
#echo -en "\e[96mIs SSL enabled for $AMBARI_HOST (yes/no) : \e[0m"
#read  "ssl"
#SSL=$ssl
#echo -en "\e[96mEnter Ambari admin's User Name: \e[0m"
#read "username"
#echo -en "\e[96mEnter Password for $username : \e[0m"
#read -s "pwd"
#LOGIN=$username
#PASSWORD=$pwd

#while true; do
#    read -p $'\n\e[96mPlease confirm if you have enabled SSL for Ambari (y/n) ? :\e[0m' yn
#    case $yn in
#        [Yy]* )  SSL=yes ; break;;
#        [Nn]* )  SSL=no ; break;;
#        * ) echo "Please answer yes or no.";;
#    esac
#done
############################################################################################################
#
#				******* SETTING PROTOCOL FOR CURL  *******
# Do not change the order of the section marked with *******
############################################################################################################

if [ -z "$SSL" ]
then
      while true; do
      read -p $'\n\e[96mPlease confirm if you have enabled SSL for Ambari (y/n) ? :\e[0m' yn
      case $yn in
         [Yy]* )  SSL=yes ; break;;
         [Nn]* )  SSL=no ; break;;
         * ) echo "Please answer yes or no.";;
      esac
    done
else
  :
fi

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

INTR=/HDP2CDP-DC-precheck
HIVECFG=$INTR/hivechecks
SCRIPTDIR=$INTR/scripts
REVIEW=$INTR/review
LOGDIR=$INTR/logs
BKP=$INTR/backup
RESOURCE=$INTR/resources
FILES=$INTR/files

today="$(date +"%Y%m%d%H%M")"
USER=`whoami`
mkdir -p $INTR/files
mkdir -p $INTR/review/hive
mkdir -p $INTR/review/os
mkdir -p $INTR/review/servicecheck
mkdir -p $INTR/scripts
mkdir -p $INTR/hivechecks
mkdir -p $INTR/logs
mkdir -p $INTR/backup
mkdir -p $INTR/resources


############################################################################################################
#
# 				 ******* CHECKING THE LIST OF SERVICES IN HDP CLUSTER *******
#  Do not change the order of the section marked with *******
############################################################################################################

echo -e "\n\e[1mCreating a list of services installed in cluster $cluster_name :$INTR/files/services.txt\e[21m"
curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/services?fields=ServiceInfo/service_name" | python -mjson.tool | perl -ne '/"service_name":.*?"(.*?)"/ && print "$1\n"' > $INTR/files/services.txt
hdfs_nameservice=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=HDFS" |  grep -w '"dfs.nameservices"' | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
echo -e "hdfs_nameservice=$hdfs_nameservice" >> $FILES/clusterconfig.properties
echo -e "\e[35m########################################################\e[0m\n"
############################################################################################################
#
#				 *******COLLECTING OTHER REQUIRED DETAILS WHICH CANNOT BE DERIVED FROM API's*******
## Do not change the order of the section marked with *******
############################################################################################################
isranger=`grep -w "RANGER" $INTR/files/services.txt`
israngerkms=`grep -w "RANGER_KMS" $INTR/files/services.txt`
ishive=`grep -w "HIVE" $INTR/files/services.txt`
iskerberos=`grep -w "KERBEROS" $INTR/files/services.txt`
isoozie=`grep -w "OOZIE" $INTR/files/services.txt`
isatlas=`grep -w "ATLAS" $INTR/files/services.txt`
isams=`grep -w "AMBARI_METRICS" $INTR/files/services.txt`
iskafka=`grep -w "KAFKA" $INTR/files/services.txt`
iszeppelin=`grep -w "ZEPPELIN" $INTR/files/services.txt`


#if [ -z "$isatlas" ]
#	then
#  	 :
#else
#	if ! [ -x "$(command -v hbase)" ]; then
# 	 echo -e "\e[31mError: hbase client is not installed.\e[0m"
#  	 exit 1
#	fi
#fi


if [ -z "$iskerberos" ]
	then
   		:
else
   	if ! [ -x "$(command -v kinit)" ]; then
   		echo -e "\e[31mError: Kerberos client is not installed.\e[0m"
  		exit 1
  	fi
fi

if [ -z "$isatlas" ]
then
   :
else
  if [ -z "$atlas_pwd" ]
  then
   echo -e "\e[31mAtlas admin password is not provided but Atlas is installed\nWill Skip Atlas PreUpgrade Check\e[0m"
   while true; do
    read -p $'\e[96mPlease confirm if you still want to continue (y/n) ? :\e[0m' yn
    case $yn in
        [Yy]* ) echo -e "" ; 
        		skipatlas=yes;	
                break;;
        [Nn]* ) echo -e "\e[96mPlease configure Atals admin password by passing parameter -ATP or --atlas_pwd  \e[0m"
        		exit;;
        * ) echo "Please answer yes or no.";;
    esac
   done
   fi
fi



if [ -z "$iszeppelin" ]
then
   :
else
	zeppelin_user=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=ZEPPELIN" |  grep -w '"zeppelin_user"' | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
	zeppelin_princ=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=ZEPPELIN" |  grep -w '"zeppelin.server.kerberos.principal"' | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
	zeppelin_keytab=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=ZEPPELIN" |  grep -w '"zeppelin.server.kerberos.keytab"' | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
	zeppelin_conf=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=ZEPPELIN" |  grep -w '"zeppelin.config.fs.dir"' | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
	zeppelin_storage=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=ZEPPELIN" |  grep -w '"zeppelin.notebook.storage"' | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
	zeppelin_notebook=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=ZEPPELIN" |  grep -w '"zeppelin.notebook.dir"' | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
	zeppelin_host=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/services/ZEPPELIN/components/ZEPPELIN_MASTER" | grep -w '"host_name"' | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
	echo -e "zeppelin_user=$zeppelin_user" >> $FILES/clusterconfig.properties
	echo -e "zeppelin_host=$zeppelin_host" >> $FILES/clusterconfig.properties
	echo -e "zeppelin_notebook=$zeppelin_notebook" >> $FILES/clusterconfig.properties
	echo -e "zeppelin_storage=$zeppelin_storage" >> $FILES/clusterconfig.properties
	echo -e "zeppelin_conf=$zeppelin_conf" >> $FILES/clusterconfig.properties
	echo -e "zeppelin_keytab=$zeppelin_keytab" >> $FILES/clusterconfig.properties
	echo -e "zeppelin_princ=$zeppelin_princ" >> $FILES/clusterconfig.properties	
fi




if [ -z "$isranger" ]
then
   :
else
#echo -en "\e[96mChecking if Password for Ranger Database is available:\e[0m\n"

  if [ -z "$RANGERPASSWORD" ]
  then
   echo -e "\e[31mRanger Database password is not provided but Ranger is installed \nWill skip Ranger Database backup and Database Compatibility check\e[0m"
   while true; do
    read -p $'\e[96mPlease confirm if you still want to continue (y/n) ? :\e[0m' yn
    case $yn in
        [Yy]* ) echo -e "" ; 
        		skipranger=yes;
        		break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
   done
   fi
 
ranger_dbhost=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER" | grep -w db_host | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
ranger_dbflavour=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER" | grep -w DB_FLAVOR | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
ranger_dbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER" | grep -w db_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
ranger_dbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER" | grep -w db_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

echo -e "ranger_dbhost=$ranger_dbhost" >> $FILES/clusterconfig.properties
echo -e "ranger_dbflavour=$ranger_dbflavour" >> $FILES/clusterconfig.properties
echo -e "ranger_dbname=$ranger_dbname" >> $FILES/clusterconfig.properties
echo -e "ranger_dbuser=$ranger_dbuser" >> $FILES/clusterconfig.properties
   
fi


if [ -z "$israngerkms" ]
then
   :
else
#echo -en "\e[96mChecking if Password for Ranger_KMS Database is available:\e[0m\n"

  if [ -z "$RANGER_KMS_PASSWORD" ]
  then
   echo -e "\e[31mRanger_KMS Database password is not provided but Ranger_KMS is installed \nWill skip Ranger_KMS Database backup and Database Compatibility check\e[0m"
   while true; do
    read -p $'\e[96mPlease confirm if you still want to continue (y/n) ? :\e[0m' yn
    case $yn in
        [Yy]* ) echo -e "" ; 
        		skiprangerkms=yes;
        		break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
   done
   fi

ranger_kmsdbhost=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_host | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
ranger_kmsdbflavour=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w DB_FLAVOR | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
ranger_kmsdbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
ranger_kmsdbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

echo -e "ranger_kmsdbhost=$ranger_kmsdbhost" >> $FILES/clusterconfig.properties
echo -e "ranger_kmsdbflavour=$ranger_kmsdbflavour" >> $FILES/clusterconfig.properties
echo -e "ranger_kmsdbname=$ranger_kmsdbname" >> $FILES/clusterconfig.properties
echo -e "ranger_kmsdbuser=$ranger_kmsdbuser" >> $FILES/clusterconfig.properties
   

fi


if [ -z "$isoozie" ]
then
   :
else
#echo -en "\e[96mChecking if Password for OOZIE Database is available:\e[0m\n"

  if [ -z "$OOZIE_PASSWORD" ]
  then
   echo -e "\e[31mOozie Database password is not provided but Oozie is installed\nWill Skip Oozie Database backup and Database Compatibility Check\e[0m"
   while true; do
    read -p $'\e[96mPlease confirm if you still want to continue (y/n) ? :\e[0m' yn
    case $yn in
        [Yy]* ) echo -e "" ; 
        		skipoozie=yes;	
                break;;
        [Nn]* ) echo -e "\e[96mPlease configure Oozie database password by passing parameter -OP or --oozie_pwd  \e[0m"
        		exit;;
        * ) echo "Please answer yes or no.";;
    esac
   done
   fi

ooziejdbcuri=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=OOZIE" |  grep oozie.service.JPAService.jdbc.url | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
oozie_dbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=OOZIE" | grep -w oozie.db.schema.name | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
oozie_dbhost=`echo $ooziejdbcuri | awk -F '/' '{print $3}'`
oozie_dbflavour=`echo $ooziejdbcuri | awk -F ':' '{print $2}'`
oozie_dbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=OOZIE" | grep -w oozie.service.JPAService.jdbc.username | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

echo -e "oozie_dbhost=$oozie_dbhost" >> $FILES/clusterconfig.properties
echo -e "oozie_dbflavour=$oozie_dbflavour" >> $FILES/clusterconfig.properties
echo -e "oozie_dbname=$oozie_dbname" >> $FILES/clusterconfig.properties
echo -e "oozie_dbuser=$oozie_dbuser" >> $FILES/clusterconfig.properties

fi


###  Entering Hive check Loop
if [ -z "$ishive" ]
then
   :
else
	# echo -en "\e[96mChecking if Password for Hive Metastore Database is available:\e[0m\n"
 	if [ -z "$hms_dbpwd" ]
 	then
   		echo -e "\e[31mHive Metastore Database is not passed \nHive has major changes, please configure password by passing -HMS or --hms parameter \e[0m"
   		while true; do
    		read -p $'\e[96mPlease confirm if you still want to continue (y/n) ? :\e[0m' yn
    		case $yn in
       		 	[Yy]* ) echo -e "" ; 
        				skiphive=yes;
       		    		break;;
        		[Nn]* ) exit;;
        		* ) echo "Please answer yes or no.";;
    		esac
   		done
   	fi

# echo -e "\n\e[1mHiveServer2 JDBC URI should be the exact string used to connect using beeline \nFor example: jdbc:hive2://c1110-node4.coelab.cloudera.com:10000/ \e[21m\n "
# echo -en "\e[96mPlease enter the JBDC URI for HiveServer2: \e[0m"
# read "hs2jdbc"
# hs2jdbcuri=$hs2jdbc
 
 
   if ! [ -x "$(command -v hive)" ]; then
   		echo -e "\e[31mError: hiveclient is not installed.\e[0m"
   		echo -e "\e[96mPREREQ - 8. HIVE CHECK\e[0m Will not give expected results.\n \e[1mPlease Install Hive Client on this node\e[21m\n"
   		while true; do
    		read -p $'\n\e[96mDo You Still Wish to Proceed without (y/n) ? :\e[0m' yn
    		case $yn in
        		[Yy]* )  echo -e "\e[31mOK! Please note HIVE 3 has major changes !!! \e[0m" ; break;;
        		[Nn]* )  exit ; break;;
        		 * ) echo "Please answer yes or no.";;
    		esac
    	done
   
	fi



############################################################################################################
#
#				 *******  TO CONFIGURE CONFIG.YAML *******
## Do not change the order of the section marked with *******
############################################################################################################


	hmsjdbc=$(curl -s -u $LOGIN:$PASSWORD --insecure $PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=HIVE | grep -w "javax.jdo.option.ConnectionURL" -A1 | tail -2 )
	hive_database_name=$(curl -s -u $LOGIN:$PASSWORD --insecure $PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=HIVE | grep hive_database_name | awk -F ':' '{print $2}' |  awk -F '"' '{print $2}' | tail -1 )
	hms_jdbc_uri=`echo $hmsjdbc | awk -F ',' '{print $1}' | awk -F '"' '{print $4}' | cut -d? -f1`
	hmsdb_user=`echo $hmsjdbc |  awk -F ',' '{print $2}' | awk -F ':' '{print $2}' | awk -F '"' '{print $2}'`
	hms_dtype=`echo $hms_jdbc_uri | awk -F ':' '{print $2}'`
	hms_dbhost=`echo $hms_jdbc_uri | awk -F '/' '{print $3}'`
	hms_warehouse=$(curl -s -u $LOGIN:$PASSWORD --insecure $PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=HIVE | grep -w '"hive.metastore.warehouse.dir"' |  awk -F ':' '{print $2}' |  awk -F '"' '{print $2}' | tail -1 )

	echo -e "hms_dbhost=$hms_dbhost" >> $FILES/clusterconfig.properties
	echo -e "hms_dtype=$hms_dtype" >> $FILES/clusterconfig.properties
	echo -e "hive_database_name=$hive_database_name" >> $FILES/clusterconfig.properties
	echo -e "hmsdb_user=$hmsdb_user" >> $FILES/clusterconfig.properties
	echo -e "hms_warehouse=$hms_warehouse" >> $FILES/clusterconfig.properties


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

 		if [ ! -f /usr/share/java/mysql-connector-java.jar ] ; then
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

## Exiting Hive check Loop
fi

echo -e "\e[35m########################################################\e[0m\n"

############################################################################################################
#
# 			********* BACKPUP : Ambari-DB / ambari.properites / ambari-env.sh *******
#
# 1. Password less ssh for ambari.properites / ambari-env.sh 
# 2. works with PGSQL and MYSQL
# 3. Need to test to for mariadb and oracle
# 4. Flow: Backup ambari.properties , ambari-env.sh | Stop Ambari | Backup Database | Start Ambari
# Do not change the order of the section marked with *******
############################################################################################################

if [ -z "$PWDSSH" ];then
   while true; do
    read -p $'\e[96mPlease confirm if password less SSH is configured between Ambari, Ranger, RangerKMS, Oozie database and this node:(y/n) ? :\e[0m' yn
    case $yn in
        [Yy]* )  export PWDSSH=y ; break;;
        [Nn]* )  export PWDSSH=n ; break;;
        * ) echo "Please answer yes(y) or no(n).";;
    esac
    done  
fi

echo -e "\e[96mPREREQ - 1. Ambari Backup :\e[0m  \e[1m Ambari Backup and Config\e[21m \n 1. Taking Backup of ambari database \n 2. Taking Backup of ambari.properties \n 3. Taking Backup of ambari-env.sh \n 4. Checking if Namenode Service Timeout Is Configured? \n"

  
if  [ "$PWDSSH" == "y" ];then
  while true; do
    read -p $'\e[96mWe will need to start and stop Ambari. Please confirm if we should proceed (y/n) ? :\e[0m' yn
    case $yn in
        [Yy]* ) sh -x $SCRIPTDIR/ambaribkp.sh $AMBARI_HOST $BKP $today $INTR $REVIEW &> $LOGDIR/ambaribkp-$today.log & 
				#sh -x $SCRIPTDIR/ambaribkp.sh $AMBARI_HOST $BKP $today $REVIEW &> $LOGDIR/ambaribkp-$today.log &
				echo -e "Please check the logs in the file: \e[1m $LOGDIR/ambaribkp-$today.log \e[21m \n"
				echo -e "Backup of ambari.properties, and ambari-env.sh is available in:\e[1m $BKP \e[21m Directory"
				echo -e "Backup of Ambari Database is available in root directory of:\e[1m $AMBARI_HOST \e[21m\n"

		        echo -e "\e[35m########################################################\e[0m\n"

				echo -e "\n\e[96mPREREQ - 2. Namenode Upgrade Timeout Check \e[0m"
				echo -e "\e[1mOutput is available in the file: $REVIEW/servicecheck/namenode-timeout-$today.out \e[21m"

				echo -e "\e[35m########################################################\e[0m\n"
				# Need to allow some time for Ambari to start and get heatbeats from all agents.
				# Increase time for large clusters
				echo -e "\e[1mWaiting for a minute for Ambari to Start & receive heatbeats from all agents\e[21m"
				# Increase time for large clusters
				sleep 90  
				break;;
        [Nn]* ) echo -e  "Please take a backup of \n1. Ambari Database: \n- Stop Ambari Server \n- Run below command from node $AMBARI_HOST\nFor Mysql: mysqldump -u ambariuser -pambaripwd ambaridb >  ambari-database-backup.sql \nFor Psql : pg_dump -U ambariuser ambaridb > ambari-database-backup.sql \n- Start Ambari Server\n"
  			    echo -e  "2. ambari.properties"
   		   		echo -e  "3. ambari-env"
  			    echo -e  "4. Please add upgrade.parameter.nn-restart.timeout based on the time of required to start namenode in /etc/ambari-server/conf/ambari.properties file on the Ambari Server host"
   
   
  			    echo -e  "Please take a backup of \n1. Ambari Database: \n- Stop Ambari Server \n- Run below command from node $AMBARI_HOST\nFor Mysql: mysqldump -u ambariuser -pambaripwd ambaridb >  ambari-database-backup.sql \nFor Psql : pg_dump -U ambariuser ambaridb > ambari-database-backup.sql \n- Start Ambari Server\n"  >> $REVIEW/servicecheck/ambari-$today.out
   				echo -e  "2. ambari.properties"  >> $REVIEW/servicecheck/ambari-$today.out
   				echo -e  "3. ambari-env"  >> $REVIEW/servicecheck/ambari-$today.out
   				echo -e  "4. Please add upgrade.parameter.nn-restart.timeout based on the time of required to start namenode in /etc/ambari-server/conf/ambari.properties file on the Ambari Server host" >> $REVIEW/servicecheck/ambari-$today.out
   				echo -e "Output is available in file:\e[1m $REVIEW/servicecheck/ambari-$today.out \e[21m" 
        		break;;
        * ) echo "Please answer yes or no.";;
      esac
   done
else
   echo -e  "Please take a backup of \n1. Ambari Database: \n- Stop Ambari Server \n- Run below command from node $AMBARI_HOST\nFor Mysql: mysqldump -u ambariuser -pambaripwd $ambaridb >  ambari-database-backup.sql \nFor Psql : pg_dump -U ambariuser ambaridb > ambari-database-backup.sql \n- Start Ambari Server\n"
   echo -e  "2. ambari.properties"
   echo -e  "3. ambari-env"
   echo -e  "4. Please add upgrade.parameter.nn-restart.timeout based on the time of required to start namenode in /etc/ambari-server/conf/ambari.properties file on the Ambari Server host"
   
   
   echo -e  "Please take a backup of \n1. Ambari Database: \n- Stop Ambari Server \n- Run below command from node $AMBARI_HOST\nFor Mysql: mysqldump -u ambariuser -pambaripwd ambaridb >  ambari-database-backup.sql \nFor Psql : pg_dump -U ambariuser ambaridb > ambari-database-backup.sql \n- Start Ambari Server\n"  >> $REVIEW/servicecheck/ambari-$today.out
   echo -e  "2. ambari.properties"  >> $REVIEW/servicecheck/ambari-$today.out
   echo -e  "3. ambari-env"  >> $REVIEW/servicecheck/ambari-$today.out
   echo -e  "4. Please add upgrade.parameter.nn-restart.timeout based on the time of required to start namenode in /etc/ambari-server/conf/ambari.properties file on the Ambari Server host" >> $REVIEW/servicecheck/ambari-$today.out
   
   echo -e "Output is available in file:\e[1m $REVIEW/servicecheck/ambari-$today.out \e[21m"
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
	echo -e "\n\e[32mRanger_KMS Is Not Installed, Skipping \e[0m \e[96mPREREQ - 2. Ranger_KMS Database Backup\e[0m"
else
	if [ "$skiprangerkms" != "yes" ];then

#ranger_kmsdbhost=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_host | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
#ranger_kmsdbflavour=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w DB_FLAVOR | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
#ranger_kmsdbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
#ranger_kmsdbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER_KMS" | grep -w db_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

		if  [ "$PWDSSH" == "y" ];then
 			 while true; do
    			read -p $'\e[96mWe will need to stop and start Ranger_KMS for Database Backup. Please confirm if we should proceed (y/n) ? :\e[0m' yn
    			case $yn in
    				[Yy]* ) echo -e "\n\e[96mPREREQ - 2. Ranger_KMS Database \e[0m \e[1mTaking Backup of Ranger_KMS DB\e[21m"
							sh -x $SCRIPTDIR/ranger_kmsdatabasebkp.sh $AMBARI_HOST $cluster_name $today $RANGER_KMS_PASSWORD $PROTOCOL $LOGIN $PASSWORD $PORT $FILES/clusterconfig.properties &> $LOGDIR/ranger_kms_databasebkp-$today.log &
        					sh -x $SCRIPTDIR/ranger_kmsdatabaseversion.sh $today $INTR  $FILES/clusterconfig.properties $RANGER_KMS_PASSWORD  &> $LOGDIR/ranger_kmsdb-version-$today.log &        		
        					echo -e "\e[1mRanger_KMS DB backup is available in Root directory of $ranger_kmsdbhost \e[21m"
        					echo -e "\e[1mRanger_KMS DB backup is available in Root directory of $ranger_kmsdbhost \e[21m"  >> $BKP/database_bkp-$today.out		      		
							echo -e "Please check the logs in the file: \e[1m$LOGDIR/ranger_kms_databasebkp-$today.log & $LOGDIR/ranger_kmsdb-version-$today.log \e[21m  \n"
							echo -e "Output is available in file:\e[1m $BKP/database_bkp-$today.out\e[21m"
							break;;
					[Nn]* ) echo -e "\n\e[96mPREREQ - 2. Ranger_KMS Database \e[0m \e[1mTaking Backup of Ranger_KMS DB\e[21m"
        					sh -x $SCRIPTDIR/ranger_kmsdatabaseversion.sh $today $INTR  $FILES/clusterconfig.properties $RANGER_KMS_PASSWORD  &> $LOGDIR/ranger_kmsdb-version-$today.log &        		
                			echo -e "\e[1mPlease take a backup of Ranger_KMS Database manually on $ranger_kmsdbhost \n- For mysql : mysqldump -u $ranger_kmsdbuser -p$RANGER_KMS_PASSWORD $ranger_kmsdbname > rangerkmsdb.sql \n- For Psql: PGPASSWORD=$RANGER_KMS_PASSWORD  pg_dump -p 5432 -U $ranger_kmsdbuser  $ranger_kmsdbname > rangerkmsdb.sql  \e[21m"
               				echo -e "\e[1mPlease take a backup of Ranger_KMS Database manually on $ranger_kmsdbhost \n- For mysql : mysqldump -u $ranger_kmsdbuser -p$RANGER_KMS_PASSWORD $ranger_kmsdbname > rangerkmsdb.sql \n- For Psql: PGPASSWORD=$RANGER_KMS_PASSWORD  pg_dump -p 5432 -U $ranger_kmsdbuser  $ranger_kmsdbname > rangerkmsdb.sql  \e[21m" >> $BKP/database_bkp-$today.out		
							echo -e "Please check the logs in the file: \e[1m$LOGDIR/ranger_kmsdb-version-$today.log \e[21m  \n"
							echo -e "Output is available in file:\e[1m $BKP/database_bkp-$today.out\e[21m"					 
        					break;;
        			* ) echo "Please answer yes or no.";;
      			esac
   			done
		else

			echo -e "\n\e[96mPREREQ - 2. Ranger_KMS Database \e[0m \e[1mTaking Backup of Ranger_KMS DB\e[21m"
        	sh -x $SCRIPTDIR/ranger_kmsdatabaseversion.sh $today $INTR  $FILES/clusterconfig.properties $RANGER_KMS_PASSWORD &> $LOGDIR/ranger_kmsdb-version-$today.log &        		
            echo -e "\e[1mPlease take a backup of Ranger_KMS Database manually on $ranger_kmsdbhost \n- For mysql : mysqldump -u $ranger_kmsdbuser -p$RANGER_KMS_PASSWORD $ranger_kmsdbname > rangerkmsdb.sql \n- For Psql: PGPASSWORD=$RANGER_KMS_PASSWORD  pg_dump -p 5432 -U $ranger_kmsdbuser  $ranger_kmsdbname > rangerkmsdb.sql  \e[21m"
            echo -e "\e[1mPlease take a backup of Ranger_KMS Database manually on $ranger_kmsdbhost \n- For mysql : mysqldump -u $ranger_kmsdbuser -p$RANGER_KMS_PASSWORD $ranger_kmsdbname > rangerkmsdb.sql \n- For Psql: PGPASSWORD=$RANGER_KMS_PASSWORD  pg_dump -p 5432 -U $ranger_kmsdbuser  $ranger_kmsdbname > rangerkmsdb.sql  \e[21m" >> $BKP/database_bkp-$today.out		
			echo -e "Please check the logs in the file: \e[1m$LOGDIR/ranger_kmsdb-version-$today.log \e[21m  \n"				
				echo -e "Output is available in file:\e[1m $BKP/database_bkp-$today.out\e[21m"			

		fi

	else
 		 echo -e "\e[31mSkipping Ranger KMS check as Ranger_KMS Database password is not configured\e[0m"

	fi

fi
####exiting [ -z "$israngerkms" ]

echo -e "\e[35m########################################################\e[0m\n"


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
	echo -e "\n\e[32mRanger Is Not Installed, Skipping \e[0m \e[96mPREREQ - 3. Ranger Database Backup\e[0m"
else

	if [ "$skipranger" != "yes" ];then
#ranger_dbhost=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER" | grep -w db_host | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
#ranger_dbflavour=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER" | grep -w DB_FLAVOR | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
#ranger_dbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER" | grep -w db_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)
#ranger_dbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=RANGER" | grep -w db_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

			if  [ "$PWDSSH" == "y" ];then
  				while true; do
   				 read -p $'\e[96mWe will need to stop and start Ranger for Database Backup. Please confirm if we should proceed (y/n) ? :\e[0m' yn
    			 case $yn in
        				[Yy]* ) echo -e "\n\e[96mPREREQ -3. Ranger Database \e[0m \e[1mTaking Backup of Ranger DB\e[21m"
                				sh -x $SCRIPTDIR/rangerdatabasebkp.sh $AMBARI_HOST $cluster_name $today $RANGERPASSWORD $PROTOCOL $LOGIN $PASSWORD $PORT $FILES/clusterconfig.properties &> $LOGDIR/rangerdatabasebkp-$today.log &
        						sh -x $SCRIPTDIR/rangerdatabaseversion.sh $today $INTR $FILES/clusterconfig.properties $RANGERPASSWORD &> $LOGDIR/rangerdb-version-$today.log &        		
        						echo -e "\e[1mRanger DB backup is available in Root directory of $ranger_dbhost \e[21m"
        						echo -e "\e[1mRanger DB backup is available in Root directory of $ranger_dbhost \e[21m" >> $BKP/database_bkp-$today.out
								echo -e "Please check the logs in the file: \e[1m$LOGDIR/rangerdatabasebkp-$today.log & $LOGDIR/rangerdb-version-$today.log \e[21m  \n"	
								echo -e "Output is available in file:\e[1m $BKP/database_bkp-$today.out\e[21m"			
								break;;
        				[Nn]* ) echo -e "\n\e[96mPREREQ -3. Ranger Database \e[0m \e[1mTaking Backup of Ranger DB\e[21m"
        						sh -x $SCRIPTDIR/rangerdatabaseversion.sh $today $RANGERPASSWORD $INTR $FILES/clusterconfig.properties $RANGERPASSWORD  &> $LOGDIR/rangerdb-version-$today.log & 
                				echo -e "\e[1mPlease take a backup of Ranger Database manually on $ranger_dbhost \n- For mysql : mysqldump -u $ranger_dbuser -p$RANGERPASSWORD $ranger_dbname > rangerdb.sql \n- For Psql: PGPASSWORD=$RANGERPASSWORD  pg_dump -p 5432 -U $ranger_dbuser  $ranger_dbname > rangerdb.sql  \e[21m"
                				echo -e "\e[1mPlease take a backup of Ranger Database manually on $ranger_dbhost \n- For mysql : mysqldump -u $ranger_dbuser -p$RANGERPASSWORD $ranger_dbname > rangerdb.sql \n- For Psql: PGPASSWORD=$RANGERPASSWORD  pg_dump -p 5432 -U $ranger_dbuser  $ranger_dbname > rangerdb.sql  \e[21m" >> $BKP/database_bkp-$today.out      
								echo -e "Please check the logs in the file: \e[1m$LOGDIR/rangerdb-version-$today.log \e[21m  \n"	        		
        						echo -e "Output is available in file:\e[1m $BKP/database_bkp-$today.out\e[21m"
        						break;;
        				* ) echo "Please answer yes or no.";;
      				esac
   				done
			else

				echo -e "\n\e[96mPREREQ -3. Ranger Database \e[0m \e[1mTaking Backup of Ranger DB\e[21m"
        		sh -x $SCRIPTDIR/rangerdatabaseversion.sh $today $INTR $FILES/clusterconfig.properties $RANGERPASSWORD &> $LOGDIR/rangerdb-version-$today.log &        		
                echo -e "\e[1mPlease take a backup of Ranger Database manually  on $ranger_dbhost \n- For mysql : mysqldump -u $ranger_dbuser -p$RANGERPASSWORD $ranger_dbname > rangerdb.sql \n- For Psql: PGPASSWORD=$RANGERPASSWORD  pg_dump -p 5432 -U $ranger_dbuser  $ranger_dbname > rangerdbbkpi$now.sql  \e[21m"
                echo -e "\e[1mPlease take a backup of Ranger Database manually on $ranger_dbhost \n- For mysql : mysqldump -u $ranger_dbuser -p$RANGERPASSWORD $ranger_dbname > rangerdb.sql \n- For Psql: PGPASSWORD=$RANGERPASSWORD  pg_dump -p 5432 -U $ranger_dbuser  $ranger_dbname > rangerdb.sql  \e[21m" >> $BKP/database_bkp-$today.out
				echo -e "Please check the logs in the file: \e[1m$LOGDIR/rangerdb-version-$today.log \e[21m  \n"				
				echo -e "Output is available in file:\e[1m $BKP/database_bkp-$today.out\e[21m"

			fi

		else
  			echo -e "\e[31mSkipping Ranger check as Ranger Database password is not configured\e[0m"

		fi

fi
####exiting [ -z "$isranger" ] BKP

sleep 10

echo -e "\e[35m########################################################\e[0m\n"

############################################################################################################
#
# 						BACKPUP : OOOZIE DATABASE
#
# 2. works with PGSQL and MYSQL
# 3. Need to test to for mariadb and oracle
# 3. Need DB password as user input values
############################################################################################################

#israngerkms=`grep -wi "RANGER_KMS" $INTR/files/services.txt | tr -s '\n ' ','`

isoozie=${isoozie%,}

if [ -z "$isoozie" ]
then
	echo -e "\n\e[32mOozie Is Not Installed, Skipping \e[0m \e[96mPREREQ - 4. Oozie Database Backup\e[0m"
else

	if [ "$skipoozie" != "yes" ];then

#ooziejdbcuri=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=OOZIE" |  grep oozie.service.JPAService.jdbc.url | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
#oozie_dbname=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=OOZIE" | grep -w oozie.db.schema.name | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
#oozie_dbhost=`echo $ooziejdbcuri | awk -F '/' '{print $3}'`
#oozie_dbflavour=`echo $ooziejdbcuri | awk -F ':' '{print $2}'`
#oozie_dbuser=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=OOZIE" | grep -w oozie.service.JPAService.jdbc.username | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tail -1)

		if  [ "$PWDSSH" == "y" ];then
 			 while true; do
  		  			read -p $'\e[96mWe will need to stop and start Oozie for Database Backup. Please confirm if we should proceed (y/n) ? :\e[0m' yn
    				case $yn in
    					[Yy]* ) echo -e "\n\e[96mPREREQ - 4. Oozie Database \e[0m \e[1mTaking Backup of Oozie DB\e[21m"
  								sh -x $SCRIPTDIR/ooziedb.sh $AMBARI_HOST $cluster_name $today $OOZIE_PASSWORD $PROTOCOL $LOGIN $PASSWORD $PORT $FILES/clusterconfig.properties &> $LOGDIR/oozie_databasebkp-$today.log &
  								sh -x $SCRIPTDIR/ooziedatabaseversion.sh $today $INTR $FILES/clusterconfig.properties $OOZIE_PASSWORD &> $LOGDIR/ooziedb-version-$today.log & 
								echo -e "\e[1mOozie DB backup is available in Root directory of $oozie_dbhost \e[21m"
        						echo -e "\e[1mOozie DB backup is available in Root directory of $oozie_dbhost \e[21m" >> $BKP/database_bkp-$today.out
	   		 					echo -e "Please check the logs in the file: \e[1m$LOGDIR/oozie_databasebkp-$today.log & $LOGDIR/ooziedb-version-$today.log \e[21m  \n"	
	    						echo -e "Output is available in file:\e[1m $BKP/database_bkp-$today.out\e[21m"			
								break;;

						[Nn]* ) echo -e "\n\e[96mPREREQ - 4. Oozie Database \e[0m \e[1mTaking Backup of Oozie DB\e[21m"
  		        				sh -x $SCRIPTDIR/ooziedatabaseversion.sh $today $INTR $FILES/clusterconfig.properties $OOZIE_PASSWORD &> $LOGDIR/ooziedb-version-$today.log & 
 		        				echo -e "\e[1mPlease take a backup of Oozie Database manually on $oozie_dbhost \n- For mysql : mysqldump -u $oozie_dbuser -p$OOZIE_PASSWORD $oozie_dbname > ooziedb.sql \n- For Psql: PGPASSWORD=$OOZIE_PASSWORD  pg_dump -p 5432 -U $oozie_dbuser  $oozie_dbname > ooziedb.sql  \e[21m"
                				echo -e "\e[1mPlease take a backup of Oozie Database manually on $oozie_dbhost \n- For mysql : mysqldump -u $oozie_dbuser -p$OOZIE_PASSWORD $oozie_dbname > ooziedb.sql \n- For Psql: PGPASSWORD=$OOZIE_PASSWORD  pg_dump -p 5432 -U $oozie_dbuser  $oozie_dbname > ooziedb.sql  \e[21m" >> $BKP/database_bkp-$today.out      
	 		    				echo -e "Please check the logs in the file: \e[1m$LOGDIR/ooziedb-version-$today.log \e[21m \n"	  		
        						echo -e "Output is available in file:\e[1m $BKP/database_bkp-$today.out\e[21m"
        						break;;
        				* ) echo "Please answer yes or no.";;
       				esac
   			done
		else

			echo -e "\n\e[96mPREREQ - 4. Oozie Database \e[0m \e[1mTaking Backup of Oozie DB\e[21m"
  			sh -x $SCRIPTDIR/ooziedatabaseversion.sh $today $INTR $FILES/clusterconfig.properties $OOZIE_PASSWORD &> $LOGDIR/ooziedb-version-$today.log & 
 		    echo -e "\e[1mPlease take a backup of Oozie Database manually on $oozie_dbhost \n- For mysql : mysqldump -u $oozie_dbuser -p$OOZIE_PASSWORD $ooziedb > ooziedb.sql \n- For Psql: PGPASSWORD=$OOZIE_PASSWORD  pg_dump -p 5432 -U $oozie_dbuser  $oozie_dbname > ooziedb.sql  \e[21m"
            echo -e "\e[1mPlease take a backup of Oozie Database manually on $oozie_dbhost \n- For mysql : mysqldump -u $oozie_dbuser -p$OOZIE_PASSWORD $oozie_dbname > ooziedb.sql \n- For Psql: PGPASSWORD=$OOZIE_PASSWORD  pg_dump -p 5432 -U $oozie_dbuser  $oozie_dbname > ooziedb.sql  \e[21m" >> $BKP/database_bkp-$today.out      
        	echo -e "Please check the logs in the file: \e[1m$LOGDIR/ooziedb-version-$today.log \e[21m  \n"
        	echo -e "Output is available in file:\e[1m $BKP/database_bkp-$today.out\e[21m"
		fi

	else
  		echo -e "\e[31mSkipping Oozie check as Oozie Database password is not configured\e[0m"

	fi

fi
####exiting [ -z "$isoozie" ]

echo -e "\e[35m########################################################\e[0m\n"

############################################################################################################
#
# 					******* CHECKING THE LIST OF SERVICES TO BE REMOVED *******
#  Do not change the order of this section.
# NOTE : This section is depended on output of  "CHECKING THE LIST OF SERVICES IN HDP CLUSTER"
############################################################################################################

echo -e "\e[96mPREREQ - 5. Unsupported Services\e[0m \e[1mServices Installed - to be deleted before upgrade\e[21m"
dep=`cat $RESOURCE/depricated-cdpdc$CDPDC.properties`
services=`egrep -wi $dep $INTR/files/services.txt | grep -v -i spark2 | tr -s '\n ' ','`
#services=`egrep -i "storm|ACCUMULO|SMARTSENSE|Superset|Flume|Mahout|Falcon|Slider|WebHCat|spark" $INTR/files/services.txt | grep -v -i spark2 | tr -s '\n ' ','`
services=${services%,}

echo -e "\e[31mBelow services are installed in cluster $cluster_name and will be deleted as a part of upgrade:\e[0m  \n \e[1m$services\e[21m\n"
echo -e "\e[31m- You can plan to remove these services before upgarde\e[0m"
echo -e "\e[31m- Removing Druid and Accumulo services cause data loss\e[0m"
echo -e "\e[31m- Do not proceed with the upgrade to HDP 7.1.1.0 if you want to continue with Druid and Accumulo services.\e[0m"
echo -e "\e[31m- Storm can be replaced with Cloudera Streaming Analytics (CSA) powered by Apache Flink. Contact your Cloudera account team for more information about moving from Storm to CSA\e[0m"
echo -e "\e[31m- You must take a backup of the running topology processes if your HDP cluster includes the Storm component.\e[0m"
echo -e "\e[31m- Flume workloads can be migrated to Cloudera Flow Management (CFM). CFM is a no-code data ingestion and management solution powered by Apache NiFi.\e[0m \n"
echo -e "########################################################\n" >>  $REVIEW/servicecheck/RemoveServices-$today.out
echo -e "Below services are installed in cluster $cluster_name and will be deleted as a part of upgrade:  \n $services \n\n * You can plan to remove these services before upgarde \n * Removing the Druid and Accumulo services cause data loss \n * Do not proceed with the upgrade to HDP 7.1.1.0 if you want to continue with Druid and Accumulo services \n * Storm can be replaced with Cloudera Streaming Analytics (CSA) powered by Apache Flink. Contact your Cloudera account team for more information about moving from Storm to CSA \n* You must take a backup of the running topology processes if your HDP cluster includes the Storm component.\n* Flume workloads can be migrated to Cloudera Flow Management (CFM). CFM is a no-code data ingestion and management solution powered by Apache NiFi\n"  >>  $REVIEW/servicecheck/RemoveServices-$today.out
echo -e "########################################################\n" >>  $REVIEW/servicecheck/RemoveServices-$today.out

#echo -e "\e[35m########################################################\e[0m\n"


############################################################################################################
#
# 					******* CHECKING HDF MPACK  *******
#  Do not change the order of this section.
# 1. Need to Add services from HDF stack : Schema Registry | SAM etc ...
# NOTE : This section is depended on output of  "CHECKING THE LIST OF SERVICES IN HDP CLUSTER"
############################################################################################################

echo -e "\e[96mPREREQ - 6. HDF Mpack Check\e[0m \e[1mChecking If Nifi Is Installed?\e[21m\n"
isnifi=`grep -wi "NIFI" $INTR/files/services.txt | tr -s '\n ' ','`
isnifi=${isnifi%,}

if [ -z "$isnifi" ];then
	echo -e "\e[1mNiFi is not installed in cluster $cluster_name\e[21m"
	echo -e "\e[1mHDF mpack check completed\e[21m\n"
else
	echo -e "\e[31mHDF Mpack is installed in $cluster_name \n Please remove it before upgrade\e[0m"
	echo -e "HDF Mpack is installed in $cluster_name \n Please remove it before upgrade" >> $REVIEW/servicecheck/RemoveServices-$today.out
	echo -e "\e[1mHDF mpack check completed\e[21m\n"
fi
echo -e "Please check the output in the file:\e[1m$REVIEW/servicecheck/RemoveServices-$today.out\e[21m for the actions to take on components installed in cluster $cluster_name\e[0m \n"
echo -e "\e[35m########################################################\e[0m\n"


############################################################################################################
#
# 					******* CHECKING FOR THIRD PARTY SERVICES *******
#  Do not change the order of this section.
# NOTE : This section is depended on output of  "CHECKING THE LIST OF SERVICES IN HDP CLUSTER"
# ADD MORE SERVICES for example: SR, SAM etc...
############################################################################################################
echo -e "\e[96mPREREQ - 7. Third Party \e[0m \e[1mThird Party Services to be deleted before upgrade\e[21m"

thirdparty=`egrep -vi "AMBARI_INFRA|FALCON|ZEPPELIN|OOZIE|LOGSEARCH|AMBARI_METRICS|ATLAS|FLUME|HBASE|HDFS|HIVE|KAFKA|MAPREDUCE2|PIG|RANGER|RANGER_KMS|SLIDER|SMARTSENSE|SPARK|SPARK2|SQOOP|TEZ|YARN|ZOOKEEPER|NIFI|NIFI_REGISTRY|REGISTRY|STREAMLINE|KERBEROS|KNOX|ACCUMULO|DRUID|MAHOUT|STORM|LOGSEARCH|SUPERSET" $INTR/files/services.txt | grep -v -i spark2 | tr -s '\n ' ','`
thirdparty=${thirdparty%,}

if [ -z "$thirdparty" ];then
	echo -e "\e[1mThere are no Third Party Services installed on this cluster $cluster_name\e[21m\n"
else
	echo -e "\e[31mBelow Third Party services are installed in cluster $cluster_name \nPlease remove this before upgrade:\e[0m \n\e[1m $thirdparty\e[21m"
	echo -e "Below Third Party services are installed in cluster $cluster_name \nPlease remove below services before upgrade: \n$thirdparty"  >> $REVIEW/servicecheck/third-party-$today.out
	echo -e "\e[1mOutput is available in the file: $REVIEW/servicecheck/third-party-$today.out \e[21m"
fi
echo -e "\e[35m########################################################\e[0m\n"



############################################################################################################
#
#                     KAFKA PREUPGRADE CHECK 
#
############################################################################################################


if [  -z "$iskafka" ]
then
		echo -e "\e[32m Will Skip\e[0m \e[96mPREREQ - 8. KAFKA PREUPGRADE CHECK\e[0m \e[31m as Kafka is not Installed\e[0m"
else
		echo -e "\e[96mPREREQ - 8. KAFKA PREUPGRADE CHECK\e[0m \e[1m as Kafka is Installed\e[21m"
		interbrokerprotocolversion=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=KAFKA" |  grep inter.broker.protocol.version | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
		logmessageformatversion=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=KAFKA" |  grep log.message.format.version | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
		
		if [  -z "$interbrokerprotocolversion"  ]
		then
			echo -e "\e[1mTo successfully upgrade Kafka, you must set the inter.broker.protocol.version to match the protocol version used by the brokers and clients.\e[21m"
			echo -e "\e[1mTo successfully upgrade Kafka, you must set the inter.broker.protocol.version to match the protocol version used by the brokers and clients.\e[21m\n" >> $REVIEW/servicecheck/kafka-check-$today.out
		else
			echo -e "\e[1mTo successfully upgrade Kafka, please confirm the value of inter.broker.protocol.version=$interbrokerprotocolversion is set correctly\e[21m"
			echo -e "\e[1mTo successfully upgrade Kafka, please confirm the value of inter.broker.protocol.version=$interbrokerprotocolversion is set correctly\e[21m\n" >> $REVIEW/servicecheck/kafka-check-$today.out
		fi
		
		if [  -z "$logmessageformatversion"  ]
		then
			echo -e "\e[1mTo successfully upgrade Kafka, you must set the log.message.format.version to match the protocol version used by the brokers and clients.\e[21m"
			echo -e "\e[1mTo successfully upgrade Kafka, you must set the log.message.format.version to match the protocol version used by the brokers and clients.\e[21m\n" >> $REVIEW/servicecheck/kafka-check-$today.out
		else
			echo -e "\e[1mTo successfully upgrade Kafka, please confirm the value of log.message.format.version=$interbrokerprotocolversion is set correctly\e[21m"
			echo -e "\e[1mTo successfully upgrade Kafka, please confirm the value of log.message.format.version=$logmessageformatversion is set correctly\e[21m\n" >> $REVIEW/servicecheck/kafka-check-$today.out
		fi
		
		echo -e "\e[1mReference : http://tiny.cloudera.com/kafkaprecheck\e[21m"
		echo -e "\e[1mReference : http://tiny.cloudera.com/kafkaprecheck\e[21m" >> $REVIEW/servicecheck/kafka-check-$today.out
	    echo -e "\n\e[1mOutput is available in the file: $REVIEW/servicecheck/kafka-check-$today.out \e[21m"

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



# Checking state of Ranger KMS to avoid failure due to ranger_kms delegation token issue
if [  -z "$israngerkms" ]
then
  echo ""
else
echo -e "\e[1mChecking Status for Ranger_KMS Service\e[0m"
kms_start=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/services/RANGER_KMS?fields=ServiceInfo/state" | grep -v href | grep -w state |  awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
while [ "$kms_start" != "STARTED" ]; do
kms_start=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/services/RANGER_KMS?fields=ServiceInfo/state" | grep -v href | grep -w state |  awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
	sleep 5
#	echo $kms_start
#	echo -e "Wating for Ranger_KMS to start"
done
echo -e "\e[1mRanger_KMS is Running\e[0m"
fi 

sleep 20


if [ -z "$ishive" ]
then
	echo -e "\e[32m Will Skip\e[0m \e[96mPREREQ - 9. HIVE CHECK\e[0m \e[31m as Hive is not Installed\e[0m"
else
	if [ "$skiphive" != "yes" ];then
		if  [ "$PWDSSH" == "y" ];then
  			while true; do
    			read -p $'\e[96mWe will need to stop and start Hive for Database Backup. Please confirm if we should proceed (y/n) ? :\e[0m' yn
    			case $yn in
    				[Yy]* ) echo -e "\e[96mPREREQ - 9. HIVE CHECK\e[0m \e[1m Hive Database Backup\e[21m"
							sh -x $SCRIPTDIR/hivedbbkp.sh $AMBARI_HOST $cluster_name $today $hms_dbpwd $PROTOCOL $LOGIN $PASSWORD $PORT $FILES/clusterconfig.properties &> $LOGDIR/hive_databasebkp-$today.log &
  							sh -x $SCRIPTDIR/hivedatabaseversion.sh $today $INTR $FILES/clusterconfig.properties $hms_dbpwd &> $LOGDIR/hivedb-version-$today.log & 
							echo -e "\e[1mHive DB backup is available in Root directory of $hms_dbhost \e[21m"
							echo -e "\e[1mHive DB backup is available in Root directory of $hms_dbhost \e[21m" >> $BKP/database_bkp-$today.out
							echo -e "Please check the logs in the file: \e[1m$LOGDIR/hive_databasebkp-$today.log & $LOGDIR/hivedb-version-$today.log \e[21m  \n"
							echo -e "Output is available in file:\e[1m $BKP/database_bkp-$today.out\e[21m"
							echo -e "Please take a snapshot of directories in:\e[1m $INTR/review/hive-hdfs-snapshot-$today.out\e[21m"			

							break;;
 		

 					[Nn]* ) echo -e "\e[96mPREREQ - 9. HIVE CHECK\e[0m \e[1m Hive Database Backup\e[21m"
 							sh -x $SCRIPTDIR/hivedatabaseversion.sh $today $INTR $FILES/clusterconfig.properties $hms_dbpwd &> $LOGDIR/hivedb-version-$today.log & 
 							echo -e "\e[1mPlease take a backup of Hive Database manually on $hms_dbhost \n- For mysql : mysqldump -u $hmsdb_user -p$hms_dbpwd $hive_database_name > hivedb.sql \n- For Psql: PGPASSWORD=$hms_dbpwd  pg_dump -p 5432 -U $hmsdb_user  $hive_database_name > hivedb.sql  \e[21m"
             			    echo -e "\e[1mPlease take a backup of Hive Database manually on $hms_dbhost \n- For mysql : mysqldump -u $hmsdb_user -p$hms_dbpwd $hive_database_name > hivedb.sql \n- For Psql: PGPASSWORD=$hms_dbpwd  pg_dump -p 5432 -U $hmsdb_user  $hive_database_name > hivedb.sql  \e[21m" >> $BKP/database_bkp-$today.out      
        					echo -e "Please check the logs in the file: \e[1m$LOGDIR/hivedb-version-$today.log \e[21m  \n"	
        					echo -e "Output is available in file:\e[1m $BKP/database_bkp-$today.out\e[21m"
        					echo -e "Please take a snapshot of directories in:\e[1m $INTR/review/hive-hdfs-snapshot-$today.out\e[21m"			
        					break;;
       	 			* ) echo "Please answer yes or no.";;
       			esac
  	 		done
		else

				echo -e "\e[96mPREREQ - 9. HIVE CHECK\e[0m \e[1m Hive Database Backup\e[21m"
 				sh -x $SCRIPTDIR/hivedatabaseversion.sh $today $INTR $FILES/clusterconfig.properties $hms_dbpwd &> $LOGDIR/hivedb-version-$today.log & 
 				echo -e "\e[1mPlease take a backup of Hive Database manually on $hms_dbhost \n- For mysql : mysqldump -u $hmsdb_user -p$hms_dbpwd $hive_database_name > hivedb.sql \n- For Psql: PGPASSWORD=$hms_dbpwd  pg_dump -p 5432 -U $hmsdb_user  $hive_database_name > hivedb.sql  \e[21m"
                echo -e "\e[1mPlease take a backup of Hive Database manually on $hms_dbhost \n- For mysql : mysqldump -u $hmsdb_user -p$hms_dbpwd $hive_database_name > hivedb.sql \n- For Psql: PGPASSWORD=$hms_dbpwd  pg_dump -p 5432 -U $hmsdb_user  $hive_database_name > hivedb.sql  \e[21m" >> $BKP/database_bkp-$today.out 
                echo -e "Please check the logs in the file: \e[1m$LOGDIR/hivedb-version-$today.log \e[21m  \n"	     
        		echo -e "Output is available in file:\e[1m $BKP/database_bkp-$today.out\e[21m"
        		echo -e "Please take a snapshot of directories in:\e[1m $INTR/review/hive-hdfs-snapshot-$today.out\e[21m"			
		fi
			echo -e "\e[96mPREREQ - 9. HIVE CHECK\e[0m \e[1mRunning Hive table check which includes:\e[21m  \n 1. Hive 3 Upgrade Checks - Locations Scan \n 2. Hive 3 Upgrade Checks - Bad ORC Filenames \n 3. Hive 3 Upgrade Checks - Managed Table Migrations ( Ownership check & Conversion to ACID tables) \n 4. Hive 3 Upgrade Checks - Compaction Check \n 5. Questionable Serde's Check \n 6. Managed Table Shadows \n"
			sh -x $SCRIPTDIR/hiveprereq.sh $INTR/files/hive_databases.txt $HIVECFG $REVIEW/hive  &> $LOGDIR/hivetablescan-$today.log &
			echo -e "Output is available in \e[1m $REVIEW/hive directory \e[21m"
			echo -e "Please check the logs in the file:\e[1m $LOGDIR/hivetablescan-$today.log  \e[21m\n"
			sleep 10

	else 
		echo -e "\e[31mSkipping Hive check as Hive Database password is not configured\e[0m"

	fi

fi

echo -e "\e[35m########################################################\e[0m\n"


############################################################################################################
#
# 					CHECKING FOR AUTO RESTART FOR ALL COMPONENTS
#
############################################################################################################

echo -e "\e[96mPREREQ - 10. AUTO RESTART \e[0m \e[1mCheck If Auto Restart Is enabled ?\e[21m "
autorestart=$(curl -s -u $LOGIN:$PASSWORD --insecure $PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/components?fields=ServiceComponentInfo/service_name,ServiceComponentInfo/recovery_enabled | grep -w '"recovery_enabled" : "true"' -B1  -A1 | grep -w '"component_name"' | awk -F ':' '{print $2}' | awk -F '"' '{print $2}' | tr -s '\n ' ',') 
autorestart=${autorestart%,}

if [ -z "$autorestart" ];then
	echo -e "\e[1mAuto Restart is disabled for all the components in $cluster_name\e[21m\n"
else
	echo -e "\e[31mPlease Disable Auto Restart for Following Components :  \e[0m \n \e[1m$autorestart\e[21m\n"
	echo -e "Please Disable Auto Restart for Following Components : \n$autorestart " >> $REVIEW/servicecheck/DisableAutoRestart-$today.out
	echo -e "\e[1mOutput is available in the file: $REVIEW/servicecheck/DisableAutoRestart-$today.out \e[21m"
fi
echo -e "\e[35m########################################################\e[0m\n"


############################################################################################################
#
# 				****	DATABASE COMPATIBLITY CHECK ** Do not change the sequence
#
############################################################################################################

echo -e "\e[96mPREREQ - 11. DATABASE COMPATIBLITY CHECK \e[0m \e[1mChecking if database versions are supported ?\e[21m "
echo -e "\e[1m Initiating Database Version Checks for required components\e[21m "

if [[ -f $INTR/files/DB-versioncheck-$today.out && -f $RESOURCE/dbcomp-cdpdc$CDPDC.properties ]]; then
	sh -x $SCRIPTDIR/dbcompatible.sh $INTR/files/DB-versioncheck-$today.out $today $REVIEW/servicecheck $CDPDC $RESOURCE &> $LOGDIR/DatabaseCompatibiltiyCheck-$today.log
	echo -e "\e[1mOutput is available in the file: $REVIEW/servicecheck/DatabaseCompatibiltiyCheck-$today.out \e[21m"
	echo -e "\e[1mPlease check the logs in the file : $LOGDIR/DatabaseCompatibiltiyCheck-$today.log  \e[21m"
else 
 	echo -e "\e[31mDatabase version file $INTR/files/DB-versioncheck-$today.out or $RESOURCE/dbcomp-cdpdc$CDPDC.properties does not exist ! \e[0m"
 	echo -e "\e[31mPlease analyse the logs: $LOGDIR/rangerdatabasebkp-$today.log $LOGDIR/ranger_kms_databasebkp-$today.log $LOGDIR/hivetablescan-$today.log or confirm if this script supports CDP-DC-$CDPDC to find the problem ! \e[0m"
fi
echo -e "\e[35m########################################################\e[0m\n"

############################################################################################################
#
# 					AMBARI VIEW Check
#
############################################################################################################

echo -e "\e[96mPREREQ - 12. AMBARI VIEW \e[0m \e[1mChecking for Instances of Ambari Views which are removed as part of upgrade ?\e[21m "
echo -e "\e[1m Initiating Ambari View Checks for required components\e[21m "

sh -x $SCRIPTDIR/ambariview.sh $AMBARI_HOST $PORT $LOGIN $PASSWORD $PROTOCOL $INTR $today $REVIEW  &> $LOGDIR/AmbariView-$today.log &
echo -e "\e[1mOutput is available in the file: $REVIEW/servicecheck/ambariview-$today.out \e[21m"
echo -e "\e[1mPlease check the logs in the file : $LOGDIR/AmbariView-$today.log  \e[21m"
echo -e "\e[35m########################################################\e[0m\n"


############################################################################################################
#
# 					CHECK IF KEYTABS & KRB5.CONF ARE NOT MANAGED BY AMBARI
#
############################################################################################################

if [ -z "$iskerberos" ];then
	echo -e "\e[32mKerberos is not enabled on $cluster_name. Skipping\e[0m \e[96mPREREQ - 13. KERBEROS CHECK \e[0m"
else
	echo -e "\e[96mPREREQ - 13. KERBEROS CHECK \e[0m \e[1mChecking If Keytab & Krb5.conf is managed by Ambari? \e[21m "
	echo -e "\e[1m Initiating Kerberos check for managed keytabs and krb5.conf \e[21m "


latestconfig=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=KERBEROS" | grep service_config_version= | awk -F ' : ' '{print $2}' |  awk -F '"' '{print $2}' | tail -1)
ismanagedkeytab=$(curl -s -u $LOGIN:$PASSWORD --insecure "$latestconfig" | grep manage_identities | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
ismanagedkrb5=$(curl -s -u $LOGIN:$PASSWORD --insecure "$latestconfig" | grep manage_krb5_conf | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
kdc_type=$(curl -s -u $LOGIN:$PASSWORD --insecure "$latestconfig" | grep kdc_type | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')



	if [[  "$ismanagedkeytab" == "true" &&  "$ismanagedkrb5" == "true" ]]; then
		echo -e "\e[32m Kerberos Keytabs & Krb5 is Managed By Ambari \n\e[0m"
		echo -e "Kerberos Keytabs & Krb5 is Managed By Ambari \n" >> $REVIEW/servicecheck/KerberoCheck-$today.out

		if  [[ "$PWDSSH" == "y" && "$kdc_type" == "mit-kdc" ]];then
			kadmin_host=$(curl -s -u $LOGIN:$PASSWORD --insecure "$latestconfig" | grep -w '"admin_server_host"' | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
  			
  			# Getting Kadmin credentials 
  			echo -en "\e[96mEnter kerberos admin principal: \e[0m"
			read "kadminprincipal"
			echo -en "\n\e[96mEnter Password for $kadminprincipal : \e[0m"
			read -s "kadmin_pwd"
			kadminprincipal=$kadminprincipal
			kadmin_pwd=$kadmin_pwd

			ssh-keygen -R $kadmin_host
			# Will get the latest host key from the specified hosts
			ssh-keyscan $kadmin_host  >> ~/.ssh/known_hosts

			kadmin_fqdn=`ssh $kadmin_host "hostname -f"`
			ssh $kadmin_host "export KRB5CCNAME=/tmp/kadmin_cc ; kinit $kadminprincipal <<<$kadmin_pwd "
			kadmin_prin_ver=`ssh $kadmin_host "kadmin.local -q listprincs | grep 'kadmin/' | grep $kadmin_fqdn"`


			if [[ "$kadmin_host" == "$kadmin_fqdn" ]]; then
    			echo -e "\e[32mFQDN is configured for Kadmin Server\e[0m"
    			echo -e "FQDN is configured for Kadmin Server" >> $REVIEW/servicecheck/KerberoCheck-$today.out
    			
			else
    			echo -e "\e[31mFQDN is NOT condfiured for Kadmin Server\e[21m"
    			echo -e "FQDN is NOT configured for Kadmin Server" >> $REVIEW/servicecheck/KerberoCheck-$today.out
    			
    		fi

			if [ -z "$kadmin_prin_ver" ]
			then
      			echo -e "\e[31mThe format of kadmin service principal expected is kadmin/fully.qualified.kdc.hostname@REALM.\nThis increased security expects a Kerberos admin service principal to be present with a specifically formatted principal name.\e[0m"
      			echo -e "\nThe format of kadmin service principal expected is kadmin/fully.qualified.kdc.hostname@REALM.\nThis increased security expects a Kerberos admin service principal to be present with a specifically formatted principal name." >> $REVIEW/servicecheck/KerberoCheck-$today.out
			else
  				echo -e "\e[32mThe format of kadmin service principal is correct $kadmin_prin_ver \e[0m"
  				echo -e "\nThe format of kadmin service principal is correct $kadmin_prin_ver " >> $REVIEW/servicecheck/KerberoCheck-$today.out
			fi

			echo -e "\e[1mPlease refer : http://tiny.cloudera.com/kadmincheck for details\e[21m"
    		echo -e "Please refer : http://tiny.cloudera.com/kadmincheck for details" >> $REVIEW/servicecheck/KerberoCheck-$today.out

		else

 			echo -e "\e[1mPlease validate below checks manually as passwordless ssh is not configured OR KDC type is not MIT_KDC \e[21m"
 			echo -e "\e[1m1. FQDN is configured for Kadmin server\n2. Format of Kadmin Service Principal Name\e[21m"

 			echo -e "Please validate below checks manually as passwordless ssh is not configured OR KDC type is not MIT_KDC" >> $REVIEW/servicecheck/KerberoCheck-$today.out
 			echo -e "1. FQDN is configured for Kadmin server\n2. Format of Kadmin Service Principal Name" >> $REVIEW/servicecheck/KerberoCheck-$today.out

 			echo -e "\e[1mPlease refer : http://tiny.cloudera.com/kadmincheck for details\e[21m"
    		echo -e "Please refer : http://tiny.cloudera.com/kadmincheck for details" >> $REVIEW/servicecheck/KerberoCheck-$today.out

		fi


	elif [[ "$ismanagedkeytab" != "true"  && "$ismanagedkrb5" != "true" ]]; then

		echo -e "\e[31m Kerberos Keytabs & Krb5 are NOT Managed By Ambari\e[21m"
		echo -e "\e[31m It is recommended to manage Kerberos Keytabs & Krb5 using Ambari before upgrade\n\e[21m \e[1mPlease consult Cloudera team for advice\e[0m"
		
		echo -e "Kerberos Keytabs & Krb5 are NOT Managed By Ambari" >> $REVIEW/servicecheck/KerberoCheck-$today.out
		echo -e "It is recommended to manage Kerberos Keytabs & Krb5 using Ambari before upgrade\nPlease consult Cloudera team for advice" >> $REVIEW/servicecheck/KerberoCheck-$today.out

	elif [[ "$ismanagedkeytab" != "true" &&  "$ismanagedkrb5" == "true" ]]; then

		echo -e "\e[31m Kerberos Keytabs are NOT Managed By Ambari\e[21m"
		echo -e "\e[31m It is recommended to manage Kerberos Keytabs using Ambari before upgrade.\n\e[21m \e[1mPlease consult Cloudera team for advice\e[0m"
		
		echo -e "Kerberos Keytabs are NOT Managed By Ambari" >> $REVIEW/servicecheck/KerberoCheck-$today.out
		echo -e "It is recommended to manage Kerberos Keytabs using Ambari before upgrade.\nPlease consult Cloudera team for advice" >> $REVIEW/servicecheck/KerberoCheck-$today.out

		if  [[ "$PWDSSH" == "y" && "$kdc_type" == "mit-kdc" ]];then
			kadmin_host=$(curl -s -u $LOGIN:$PASSWORD --insecure "$latestconfig" | grep -w '"admin_server_host"' | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
  			
  			# Getting Kadmin credentials 
  			echo -en "\e[96mEnter kerberos admin principal: \e[0m"
			read "kadminprincipal"
			echo -en "\n\e[96mEnter Password for $kadminprincipal : \e[0m"
			read -s "kadmin_pwd"
			kadminprincipal=$kadminprincipal
			kadmin_pwd=$kadmin_pwd

			ssh-keygen -R $kadmin_host
			# Will get the latest host key from the specified hosts
			ssh-keyscan $kadmin_host  >> ~/.ssh/known_hosts

			kadmin_fqdn=`ssh $kadmin_host "hostname -f"`
			ssh $kadmin_host "export KRB5CCNAME=/tmp/kadmin_cc ; kinit $kadminprincipal <<<$kadmin_pwd "
			kadmin_prin_ver=`ssh $kadmin_host "kadmin.local -q listprincs | grep 'kadmin/' | grep $kadmin_fqdn"`


			if [[ "$kadmin_host" == "$kadmin_fqdn" ]]; then
    			echo -e "\e[32mFQDN is configured for Kadmin Server\e[0m"
    			echo -e "FQDN is configured for Kadmin Server" >> $REVIEW/servicecheck/KerberoCheck-$today.out
    			
			else
    			echo -e "\e[31mFQDN is NOT condfiured for Kadmin Server\e[21m"
    			echo -e "FQDN is NOT configured for Kadmin Server" >> $REVIEW/servicecheck/KerberoCheck-$today.out
    			
    		fi

			if [ -z "$kadmin_prin_ver" ]
			then
      			echo -e "\e[31mThe format of kadmin service principal expected is kadmin/fully.qualified.kdc.hostname@REALM.\nThis increased security expects a Kerberos admin service principal to be present with a specifically formatted principal name.\e[0m"
      			echo -e "\nThe format of kadmin service principal expected is kadmin/fully.qualified.kdc.hostname@REALM.\nThis increased security expects a Kerberos admin service principal to be present with a specifically formatted principal name." >> $REVIEW/servicecheck/KerberoCheck-$today.out
			else
  				echo -e "\e[32mThe format of kadmin service principal is correct $kadmin_prin_ver \e[32m"
  				echo -e "\nThe format of kadmin service principal is correct $kadmin_prin_ver " >> $REVIEW/servicecheck/KerberoCheck-$today.out
			fi

			echo -e "\e[1mPlease refer : http://tiny.cloudera.com/kadmincheck for details\e[21m"
    		echo -e "Please refer : http://tiny.cloudera.com/kadmincheck for details" >> $REVIEW/servicecheck/KerberoCheck-$today.out

		else

 			echo -e "\e[1mPlease validate below checks manually as passwordless ssh is not configured OR KDC type is not MIT_KDC \e[21m"
 			echo -e "\e[1m1. FQDN is configured for Kadmin server\n2. Format of Kadmin Service Principal Name\e[21m"

 			echo -e "Please validate below checks manually as passwordless ssh is not configured OR KDC type is not MIT_KDC" >> $REVIEW/servicecheck/KerberoCheck-$today.out
 			echo -e "1. FQDN is configured for Kadmin server\n2. Format of Kadmin Service Principal Name" >> $REVIEW/servicecheck/KerberoCheck-$today.out

 			echo -e "\e[1mPlease refer : http://tiny.cloudera.com/kadmincheck for details\e[21m"
    		echo -e "Please refer : http://tiny.cloudera.com/kadmincheck for details" >> $REVIEW/servicecheck/KerberoCheck-$today.out

		fi

	else

		echo -e "\e[31m Kerberos Krb5.conf is NOT Managed By Ambari\e[21m"
		echo -e "\e[31m It is recommended to manage Kerberos krb5.conf using Ambari before upgrade.\n\e[21m \e[1mPlease consult Cloudera team for advice\e[0m"
		
		echo -e "Kerberos Krb5.conf is NOT Managed By Ambari"  >> $REVIEW/servicecheck/KerberoCheck-$today.out
		echo -e "It is recommended to manage Kerberos krb5.conf using Ambari before upgrade.\nPlease consult Cloudera team for advice"  >> $REVIEW/servicecheck/KerberoCheck-$today.out
	fi

echo -e "\e[1mOutput is available in the file: $REVIEW/servicecheck/KerberoCheck-$today.out \e[21m"

fi

echo -e "\e[35m########################################################\e[0m\n"
############################################################################################################
#
# 					 Operating System Compatibility  CHECK
#
# 1. Check OS compatibility on all Nodes : ONLY MAJOR VERSION (limitation because of Ambari API)
# 2. If want to check minor version need to configure a different script
############################################################################################################


echo -e "\n\e[96mPREREQ - 14. OS & Service Check \e[0m  \e[1mChecking OS compatibility and running service check\e[21m"

sh -x $SCRIPTDIR/oscheck.sh $AMBARI_HOST $PORT $LOGIN $PASSWORD $REVIEW/os $today $INTR/files/ $PROTOCOL &> $LOGDIR/oscheck-$today.log  &

echo -e "\e[1mOutput is available in the file: $REVIEW/os/oscheck-$today.out \e[21m"
echo -e "Please check the logs in the file: \e[1m$LOGDIR/oscheck-$today.log\e[21m\n"
echo -e "\e[35m########################################################\e[0m\n"


############################################################################################################
#
# 					 Maintenance Mode
#
# 
# 
############################################################################################################

echo -e "\e[96mPREREQ - 15. Maintenance Mode \e[0m"
mmode=`egrep -i "SMARTSENSE|LOGSEARCH|AMBARI_METRICS" $INTR/files/services.txt | tr -s '\n ' ','`
mmode=${mmode%,}

echo -e "\e[1m Enable Maintenance Mode for $mmode\e[21m"
echo -e "\e[1m Stop LOGSEARCH if installed\e[21m"
echo -e "\e[1m Enable Maintenance Mode for $mmode\e[21m" >> $REVIEW/servicecheck/mmode-$today.out
echo -e "\n\e[1m Stop LOGSEARCH if installed\e[21m" >> $REVIEW/servicecheck/mmode-$today.out
echo -e "\e[1mOutput is available in the file: $REVIEW/servicecheck/mmode-$today.out \e[21m"
echo -e "\e[35m########################################################\e[0m\n"


############################################################################################################
#
# 					 Ambari Metrics Pre-Upgrade Check
#
# 1. Need to run pre upgrade script. 
# 2. Need to automate pre upgrade for AMS
############################################################################################################

if [ -z "$isams" ];then
	echo -e "\e[32mAmbari Metrics Server is not installed on $cluster_name. Skipping\e[0m \e[96mPREREQ - 16. Ambari Metrics Server CHECK \e[0m"
else
	echo -e "\e[96mPREREQ - 16. Ambari Metrics Server CHECK \e[0m"
	cat $RESOURCE/ams-cdpdc$CDPDC.properties > $REVIEW/servicecheck/amscheck-$today.out
	#cat $RESOURCE/ams-cdpdc$CDPDC.properties
	echo -e "\e[1mBackup AMS before upgrading Ambari by following the steps (3) mentioned in below document:\e[21m"
	echo -e "\e[1mhttp://tiny.cloudera.com/amsbkp\e[21m\n"
    echo -e "\e[1mAfter Upgrading Ambari please follow below steps:\e[21m"
    echo -e "\e[1m- Stop Ambari Metrics Service and SmartSense"
    echo -e "\e[1m- Manually upgrade AMS and Smart Sense : http://tiny.cloudera.com/ams-ss-upgrade\e[21m"	
	echo -e "\e[1mOutput is available in the file: $REVIEW/servicecheck/amscheck-$today.out \e[21m"
fi

echo -e "\e[35m########################################################\e[0m\n"

############################################################################################################
#
#                    Atlas Upgrade Precheck
# 
#
############################################################################################################
#sleep 30
#if [ -z "$isatlas" ]
#then
#	echo -e "\n\e[32mAtlas Is Not Installed, Skipping Skipping\e[0m \e[96mPREREQ - 15. ATLAS BACKUP \e[0m"
#else
#	while true; do
#    read -p $'\n\e[96mDo You Wish to take backup of Atlas Hbase tables (ATLAS_ENTITY_AUDIT_EVENTS & atlas_titan) (y/n) ? :\e[0m' yn
#    case $yn in
#        [Yy]* )   echo -e "\e[96mPREREQ - 16. ATLAS BACKUP\e[0m \e[1mRunning Atlas Backup:\e[21m  \n 1. Hbase table backup \n 2. Shard backup \n"
#                  sh -x $SCRIPTDIR/atlasbkp.sh $AMBARI_HOST $PORT $LOGIN $PASSWORD $PROTOCOL $cluster_name $today $iskerberos &> $LOGDIR/atlasbkp-$today.log &
#				  echo -e "Please check the logs in file:\e[1m $LOGDIR/atlasbkp-$today.log   \e[21m"
# 				  echo -e "Check the status of the applicationsID in file:\e[1m $LOGDIR/atlasbkp-$today.log \e[21m"
#				  echo -e "Backup of hbase tables is stored in HDFS directory /atlasbackup$today   \e[21m"
#				  break;;
#        [Nn]* )   echo -e "\e[1m Please take a backup of Atlas Hbase tables (ATLAS_ENTITY_AUDIT_EVENTS & atlas_titan) manually \e[21m";
#         break;;
#        * ) echo "Please answer yes or no.";;
#    esac
#    done
#    
#	sleep 10
#fi

if [ -z "$isatlas" ]
then
	echo -e "\n\e[32mAtlas Is Not Installed, Skipping\e[0m \e[96mPREREQ - 17. ATLAS PREUPGRADE CHECK \e[0m"
else

	if [ "$skipatlas" != "yes" ];then
		echo -e "\n\e[96mPREREQ - 17. ATLAS PREUPGRADE CHECK \e[0m"
		atlas_username=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=ATLAS" |  grep atlas.admin.username | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
		atlasuri=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=ATLAS" |  grep atlas.rest.address | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}' | awk -F ',' '{print $1}')
		atlasheap=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=ATLAS" |  grep -w '"atlas_server_xmx"' | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
		atlasbatchsize=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=ATLAS" |  grep atlas.migration.mode.batch.size | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
		atlasworkers=$(curl -s -u $LOGIN:$PASSWORD --insecure "$PROTOCOL://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=ATLAS" |  grep atlas.migration.mode.workers | tail -1 | awk -F ' : ' '{print $2}' | awk -F '"' '{print $2}')
	
	
		curl -s -g -X GET -u $atlas_username:$atlas_pwd -H "Content-Type: application/json" -H"Cache-Control: no-cache" "$atlasuri/api/atlas/admin/metrics" | python -mjson.tool >> $FILES/atlas-entity-$today.out
		entityCount=`grep entityCount $FILES/atlas-entity-$today.out | awk -F ':' '{print $2}'`
		entityCount=${entityCount%,}
	
		echo -e "\e[1mTotal number of Atlas Entities: $entityCount\e[21m"
		echo -e "Total number of Atlas Entities: $entityCount" >> $REVIEW/atlas-preupgrade-$today.out

		echo -e "\e[1mHeap Space of Atlas Server: $atlasheap\e[21m"
		echo -e "Heap Space of Atlas Server: $atlasheap" >> $REVIEW/servicecheck/atlas-preupgrade-$today.out

		if [ -z "$atlasbatchsize" ]
		then
			echo -e "\e[1m\e[1matlas.migration.mode.batch.size: Not Configured\e[21m"
			echo -e "atlas.migration.mode.batch.size: Not Configured" >> $REVIEW/servicecheck/atlas-preupgrade-$today.out
		else
			echo -e "\e[1matlas.migration.mode.batch.size: $atlasbatchsize\e[21m"
			echo -e "atlas.migration.mode.batch.size: $atlasbatchsize" >> $REVIEW/servicecheck/atlas-preupgrade-$today.out
		fi
	
		if [ -z "$atlasworkers" ]
		then
			echo -e "\e[1matlas.migration.mode.workers: Not Configured\e[21m"
			echo -e "atlas.migration.mode.workers: Not Configured" >> $REVIEW/servicecheck/atlas-preupgrade-$today.out
		else
			echo -e "\e[1matlas.migration.mode.workers: $atlasworkers\e[21m"
			echo -e "atlas.migration.mode.workers: $atlasworkers" >> $REVIEW/servicecheck/atlas-preupgrade-$today.out
		fi
			echo -e "\e[1mReference : http://tiny.cloudera.com/atlasprecheck\e[21m"
		echo -e "Please Refer : http://tiny.cloudera.com/atlasprecheck" >> $REVIEW/servicecheck/atlas-preupgrade-$today.out
		
		echo -e "\n\e[1mOutput is available in the file: $REVIEW/servicecheck/atlas-preupgrade-$today.out \e[21m"
		
	else
			echo -e "\n\e[32mAtlas admin password is not set, Skipping\e[0m \e[96mPREREQ - 17. ATLAS PREUPGRADE CHECK \e[0m"
	fi 
	# skipatlas check completed
	
fi	

echo -e "\e[35m########################################################\e[0m\n"

############################################################################################################
#
# 					ZEPPELIN PREUPGRADE CHECK
#
# 1. all notebooks from HDFS to local FS
# 2 Copy the interpreter.json and notebook-authorization.json
############################################################################################################
if [ -z "$iszeppelin" ]
then
	echo -e "\n\e[32mZeppelin Is Not Installed, Skipping\e[0m \e[96mPREREQ - 18. ZEPPELIN PREUPGRADE STEPS \e[0m"
else
 	if  [ "$PWDSSH" == "y" ];then
  			while true; do
    			read -p $'\n\e[96m Initiating Backup of Notebook and Conf Directory from HDFS to local filesystem on $zeppelin_host. Please confirm if we should proceed (y/n) ? :\e[0m' yn
    			case $yn in
    				[Yy]* ) echo -e "\e[96mPREREQ - 18. ZEPPELIN PREUPGRADE STEPS \e[0m"
  
							sh -x $SCRIPTDIR/zeppelinbkp.sh $FILES/clusterconfig.properties $iskerberos &> $LOGDIR/zeppelin-preupgrade-$today.log &
							echo -e "\e[1mBackup of all notebooks is available on $zeppelin_host in /var/lib/zeppelin/$zeppelin_notebook \e[21m"
							echo -e "Backup of all notebooks is available on $zeppelin_host in /var/lib/zeppelin/$zeppelin_notebook" >> $REVIEW/servicecheck/zeppelin-preupgrade-$today.out
							echo -e "\e[1mBackup of interpreter.json and notebook-authorization.json is available on $zeppelin_host in /var/lib/zeppelin/$zeppelin_conf \e[21m"
							echo -e "Backup of interpreter.json and notebook-authorization.json is available on $zeppelin_host in /var/lib/zeppelin/$zeppelin_conf" >> $REVIEW/servicecheck/zeppelin-preupgrade-$today.out
							echo -e "Please check the logs in the file: \e[1m$LOGDIR/zeppelin-preupgrade-$today.log\e[21m \n"	
							break;;
 		
 					[Nn]* ) echo -e "\e[96mPREREQ - 18. ZEPPELIN PREUPGRADE STEPS \e[0m"
 							echo -e "\e[1mPlease take a backup Zeppelin Notebook and Conf dir from HDFS to local filesystem on $zeppelin_host \e[21m"
 							echo -e "Please take a backup Zeppelin Notebook and Conf dir from HDFS to local filesystem on $zeppelin_host" >> $REVIEW/servicecheck/zeppelin-preupgrade-$today.out
        					echo -e "\e[1mPlease refer http://tiny.cloudera.com/zeppelinprecheck for detail steps"
        					echo -e "Please refer http://tiny.cloudera.com/zeppelinprecheck for detail steps"  >> $REVIEW/servicecheck/zeppelin-preupgrade-$today.out

        					echo -e "Output is available in file: \e[1m$REVIEW/servicecheck/zeppelin-preupgrade-$today.out\e[21m"
        					break;;
       	 			* ) echo "Please answer yes or no.";;
       			esac
  	 		done
		else
			echo -e "\e[96mPREREQ - 18. ZEPPELIN PREUPGRADE STEPS \e[0m"
 			echo -e "\e[1mPlease take a backup Zeppelin Notebook and Conf dir from HDFS to local filesystem on $zeppelin_host \e[21m"
 			echo -e "Please take a backup Zeppelin Notebook and Conf dir from HDFS to local filesystem on $zeppelin_host" >> $REVIEW/servicecheck/zeppelin-preupgrade-$today.out
        	echo -e "\e[1mPlease refer http://tiny.cloudera.com/zeppelinprecheck for detail steps"
        	echo -e "Please refer http://tiny.cloudera.com/zeppelinprecheck for detail steps"  >> $REVIEW/servicecheck/zeppelin-preupgrade-$today.out

        	echo -e "Output is available in file: \e[1m$REVIEW/servicecheck/zeppelin-preupgrade-$today.out\e[21m"
		fi	  

fi 

echo -e "\e[35m########################################################\e[0m\n"


############################################################################################################
#
# 					 SERVICE CHECK
#
# 1. Will run service checks on all the services installed in cluster.
############################################################################################################

echo -e "\e[96mPREREQ - 19. Service Check \e[0m  \e[1mrunning service check\e[21m"
while true; do
    read -p $'\n\e[96mAre you sure you wish to run service check on all components (y/n) ? :\e[0m' yn
    case $yn in
        [Yy]* ) sh -x $SCRIPTDIR/run_all_service_check.sh $AMBARI_HOST $PORT $LOGIN $PASSWORD $REVIEW/os $today $INTR/files/ $PROTOCOL &> $LOGDIR/os-servicecheck-$today.log  &
         break;;
        [Nn]* )  exit ; break;;
        * ) echo "Please answer yes or no.";;
    esac
done
echo -e "Please check the logs in the file: \e[1m$LOGDIR/os-servicecheck-$today.log\e[21m\n"
echo -e "\e[35m########################################################\e[0m\n"


