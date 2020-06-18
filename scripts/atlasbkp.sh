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
PORT=$2
LOGIN=$3
PASSWORD=$4
protocol=$5
cluster_name=$6
iskerberos=$9
now=$7
scriptdir=$8
backdir=atlasbackup$now


hdfsconfig=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=HDFS" | grep service_config_version= | awk -F ' : ' '{print $2}' |  awk -F '"' '{print $2}' | tail -1)

hbaseconfig=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=HBASE" | grep service_config_version= | awk -F ' : ' '{print $2}' |  awk -F '"' '{print $2}' | tail -1)


if [ -n "$iskerberos" ]
then

hdfs_user=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hdfsconfig" | grep hdfs_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
hdfs_user_keytab=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hdfsconfig" | grep hdfs_user_keytab | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
hdfs_principal_name=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hdfsconfig" | grep hdfs_principal_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}'

hbase_user=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hbaseconfig" | grep hbase_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
hbase_user_keytab=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hbaseconfig" | grep hbase_user_keytab | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
hbase_principal_name=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hbaseconfig" | grep hbase_principal_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')

hdfsuser=`hadoop org.apache.hadoop.security.HadoopKerberosName $hdfs_principal_name | awk -F ' ' '{print $4}'`
hbaseuser=`hadoop org.apache.hadoop.security.HadoopKerberosName $hbase_principal_name | awk -F ' ' '{print $4}'`)

echo -e "######################################################## \n"
echo -e "Running kinit for HDFS user \n"
kinit -kt $hdfs_user_keytab $hdfs_principal_name
echo -e "######################################################## \n"
echo -e "Confirming TGT for HDFS user \n"
klist
echo -e "######################################################## \n"
echo -e "Creating backup dir /$backdir in HDFS  \n"
hdfs dfs -mkdir /$backdir
echo -e "######################################################## \n"
echo -e "Changing the permission of /$backdir to $hbaseuser:$hdfsuser \n"
hdfs dfs -chown $hbaseuser:$hdfsuser /$backdir
echo -e "######################################################## \n"


echo -e "Running kinit for HBASE user \n"
kinit -kt $hbase_user_keytab $hbase_principal_name
echo -e "######################################################## \n"
echo -e "Confirming TGT for HBASE user \n"
klist
echo -e "######################################################## \n"
echo -e "Taking a backup of atlas_titan hbase table in /$backdir \n"
hbase org.apache.hadoop.hbase.mapreduce.Export "atlas_titan" "/$backdir/atlas_titan"
echo -e "######################################################## \n"
echo -e "Taking a backup of ATLAS_ENTITY_AUDIT_EVENTS  hbase table in /$backdir \n"
hbase org.apache.hadoop.hbase.mapreduce.Export "ATLAS_ENTITY_AUDIT_EVENTS" "/$backdir/ATLAS_ENTITY_AUDIT_EVENTS"
echo -e "######################################################## \n"e

else

hdfs_user=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hdfsconfig" | grep -w '"hdfs_user"'| awk -F ':' '{print $2}' | awk -F '"' '{print $2}') 
hbase_user=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hbaseconfig" | grep -w '"hbase_user"' | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')

#sh -x $scriptdir/createhdfs.sh  $hdfs_user $hbase_user $backdir && sleep 5
#su - $hdfsuser
#echo -e "Creating backup dir /$backdir in HDFS  \n"
#hdfs dfs -mkdir /$backdir
#echo -e "######################################################## \n"
#echo -e "Changing the permission of /$backdir to $hbaseuser:$hdfsuser \n"
#hdfs dfs -chown $hbaseuser:$hdfsuser /$backdir


sudo -u $hdfs_user hadoop fs -mkdir /$backdir && sudo -u $hdfs_user hadoop fs -chown $hbase_user:$hdfs_user /$backdir && sleep 2

if [ $? -eq 0 ]; then

echo -e "######################################################## \n"
echo -e "Taking a backup of atlas_titan hbase table in /$backdir \n"
hbase org.apache.hadoop.hbase.mapreduce.Export "atlas_titan" "/$backdir/atlas_titan"
echo -e "######################################################## \n"

echo -e "Taking a backup of ATLAS_ENTITY_AUDIT_EVENTS  hbase table in /$backdir \n"
 hbase org.apache.hadoop.hbase.mapreduce.Export "ATLAS_ENTITY_AUDIT_EVENTS" "/$backdir/ATLAS_ENTITY_AUDIT_EVENTS"
echo -e "######################################################## \n"

else 
echo -e "Unable to create hdfs directory. Please check '$scriptdir/createhdfs.sh' "
fi

fi
