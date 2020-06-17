#1/bin/bash
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
iskerberos=$7
now=$8
backdir=atlasbackup$now


hdfsconfig=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=HDFS" | grep service_config_version= | awk -F ' : ' '{print $2}' |  awk -F '"' '{print $2}' | tail -1)

hbaseconfig=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARIHOST:$PORT/api/v1/clusters/$cluster_name/configurations/service_config_versions?service_name=HBASE" | grep service_config_version= | awk -F ' : ' '{print $2}' |  awk -F '"' '{print $2}' | tail -1)

hdfs_user=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hdfsconfig" | grep hdfs_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
hdfs_user_keytab=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hdfsconfig" | grep hdfs_user_keytab | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
hdfs_principal_name=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hdfsconfig" | grep hdfs_principal_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')

# kinit -kt /etc/security/keytabs/hdfs.headless.keytab hdfs-c3110@COELAB.CLOUDERA.COM
# hdfs dfs -mkdir /atlasbackup
# hdfs dfs -chown hbase:hbase /atlasbackup

hbase_user=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hbaseconfig" | grep hbase_user | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
hbase_user_keytab=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hbaseconfig" | grep hbase_user_keytab | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')
hbase_principal_name=$(curl -s -u $LOGIN:$PASSWORD --insecure "$hbaseconfig" | grep hbase_principal_name | awk -F ':' '{print $2}' | awk -F '"' '{print $2}')

#su - hbase
# kinit -kt /etc/security/keytabs/hbase.headless.keytab hbase-c3110@COELAB.CLOUDERA.COM
# hbase org.apache.hadoop.hbase.mapreduce.Export "atlas_titan" "/backup/atlas_titan1"
# hbase org.apache.hadoop.hbase.mapreduce.Export "ATLAS_ENTITY_AUDIT_EVENTS" "/backup/ATLAS_ENTITY_AUDIT_EVENTS"

hdfsuser=`hadoop org.apache.hadoop.security.HadoopKerberosName $hdfs_principal_name | awk -F ' ' '{print $4}'`
hbaseuser=`hadoop org.apache.hadoop.security.HadoopKerberosName $hbase_principal_name | awk -F ' ' '{print $4}'`

if [ -n "$iskerberos" ]
then
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

su - $hdfsuser
echo -e "Creating backup dir /$backdir in HDFS  \n"
hdfs dfs -mkdir /$backdir
echo -e "######################################################## \n"
echo -e "Changing the permission of /$backdir to $hbaseuser:$hdfsuser \n"
hdfs dfs -chown $hbaseuser:$hdfsuser /$backdir

exit

echo -e "######################################################## \n"
echo -e "Taking a backup of atlas_titan hbase table in /$backdir \n"
hbase org.apache.hadoop.hbase.mapreduce.Export "atlas_titan" "/$backdir/atlas_titan"
echo -e "######################################################## \n"

echo -e "Taking a backup of ATLAS_ENTITY_AUDIT_EVENTS  hbase table in /$backdir \n"
hbase org.apache.hadoop.hbase.mapreduce.Export "ATLAS_ENTITY_AUDIT_EVENTS" "/$backdir/ATLAS_ENTITY_AUDIT_EVENTS"
echo -e "######################################################## \n"

fi
