## HDP2.6 To CDP-DC Preupgrade Checks (WIP) 

This tool is to help customers to prepare and plan for upgrade from HDP to CDP-DC. Helps to get details on what actions are required before upgrading the HDP 2.x clusters.

The intent is to save the time required to prepare and perform upgrade. 


#### Check and Validations Performed

* Ambari Database, ambari.properties and ambari-env backup

* RangerKMS Database Backup

* Ranger Database Backup

* Oozie Database Backup

* Deprecated Components

* HDF Mpack

* Third Party Services

* Kafka PreUpgrade Check ( Ambari Manages Krb5/keytabs, Kadmin principal Hostname Check (MIT_KDC) , KDC Admin Host FQDN (MIT_KDC))

* [Hive Pre Upgrade](https://github.com/dstreev/cloudera_upgrade_utils/blob/master/hive-sre/README.md)
1. Hive 3 Upgrade Checks - Locations Scan
2. Hive 3 Upgrade Checks - Bad ORC Filenames
3. Hive 3 Upgrade Checks - Managed Table Migration
4. Hive 3 Upgrade Checks - Compaction Check
5. Questionable Serde's Check
6. Managed Table Shadows
7. Hive PreUpgrade Checks - HDFS snapshots

* Ambari Auto Restart Enabled

* Database Compatibility 

* Ambari Views 

* Ambari Managed Keytabs and krb5.conf

* OS Compatibility 

* Maintenance Mode

* Ambari Metrics Server check (WIP)

* Atlas PreUpgrade Check

* Preparing Zeppelin before preupgrade 

* Service Check

### To Add 

1. Hbase PreUpgrade Check 
2. Kadmin principal Hostname Check (for AD)/ KDC Admin Host FQDN (for AD) / KDC Admin Credentials ??
5. Config Group for multiple HS2 servers
6. Support For Ubuntu and Oracle DB
7. Backup of Data Dir for Databases 
8. Host Maintenance Mode
9. Disk Space
10. Service Maintenance Mode
11. Backing up Ambari infra data and migrating Atlas data
12. Checkpoint HDFS

### Environment Settings

To ease the launch of this script :

1. Make sure below packages are installed :

Packages: wget postgresql mysql/mariadb mysql-connector-java postgresql-jdbc perl python
Clients : hdfs yarn mapreduce2 tez hbase hive

2. Configure access to Ambari, Ranger, RangerKMS, HiveMetastore and Oozie database from the node on which script is to be executed:

```
To confirm access to database :

For Mysql :
mysql -h <database-host> -u <user> -p<password> <database-name>

For example:
mysql -h node3.example.com -u rangerdba -prangerdba ranger

For Postgres:
psql -h <database-host> -U <user> <databasename>
Enter Password for user:

For example:
psql -h node3.example.com -u rangerdba ranger
Enter Password for rangerdba: 
```

3. Configure passwordless SSH access between edge node to Ambari, Zeppelin Master, KDC/Kadmin server & Database server(Ambari, Ranger, RangerKMS, HiveMetastore and Oozie)
*Note: If passwordless SSH cannot be configured you will have to perform few checks manually.

4. Hive Client Must be Installed on the node where this script is executed.

5. For unsecured cluster : (This is required for Hive Pre Upgrade check & Atlas hbase table backup)
```
- Create home directory for root user in hdfs ;
 $ su - hdfs 
 $  hdfs dfs -mkdir /user/root 
 $ hdfs dfs -chown root:root /user/root
 
- Enable acls for hdfs by configuring dfs.namenode.acls.enabled=true in custom hdfs-site.xml. Restart required services

- Set acl for root :
$ hdfs dfs -setfacl -R -m user:root:rwx /

- Execute the script prereqwrapper.sh with required parameters as described below.

- Once script is completed remove the acl for the root user 
$ hdfs dfs -setfacl -x user:root /


```

6. For Secured Cluster : (This is required for Hive Pre Upgrade check)
```
 - Give ambari-qa user readonly permission to all paths in HDFS in Ranger
 
 - As root user get kerberos ticket for the ambari-qa user for which you created policy 
 $ kinit -kt /etc/security/keytabs/smokeuser.headless.keytab ambari-qa-c3110@REALMNAME
 $ klist 

- Execute the script prereqwrapper.sh with required parameters as described below

```

### How to execute ?

1. Clone this repository on the edge node

2. Run the prereqwrapper.sh script with required  parameters:
```
$ sh /HDP2CDP-DC-precheck/scripts/prereqwrapper.sh --cdpdc_version=X.X.X --ambari=<ambari-hostname> --port=<port> --user=<ambari-admin> --password=<ambari-admin-pwd> --ssl=<yes/no> --hms=<HMS_DB_PWD>  --ranger_pwd=<RANGER_DB_PWD> --ranger_kms_pwd=<RANGERKMS_DB_PWD> --oozie_pwd=<OOZIE_DB_PWD>

REQUIRED:
-A 	| --ambari   		: Ambari Hostname
-P  | --port			: Ambari Port
-U  | --user			: Ambari Admin User
-PWD| --passwod			: Ambari Admin Password
-S  | --ssl				: SSL enabled (yes/no)
-CDPDC |--cdpdc_version : CDP-DC version to upgrade to

OPTIONAL:
-HMS| --hms				: Hive Metasore Database Password
-RP | --ranger_pwd  	: Ranger Database Password
-RKP| --ranger_kms_pwd	: Ranger KMS Database Password
-OP | --oozie_pwd		: Ooize Database Password
-AP | --atlas_pwd		: Altas Admin Password 

For example :
# sh /HDP2CDP-DC-precheck/scripts/prereqwrapper.sh  --cdpdc_version=7.1.1 --ambari=c3110-node1 --port=8080 --user=admin --password=amankumbare --ssl=no --hms=hadoop  --ranger_pwd=rangerdba --ranger_kms_pwd=rangerkms --oozie_pwd=akshayoozie --atlas_pwd=admin

```

### Results 

- Backups are available in /HDP2CDP-DC-precheck/backup

- Outputs are available in /HDP2CDP-DC-precheck/review

- Logs are available in /HDP2CDP-DC-precheck/logs

*Feedback* For any feedback please send an email to amankumbare@cloudera.com
