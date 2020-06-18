## HDP2.6 To CDP-DC Preupgrade Checks

This tool is to help customers to prepare and plan for upgrade from HDP to CDP-DC. Helps to get details on what actions are required before upgrading the HDP 2.x clusters.

The intent is to save the time required to prepare and perform upgrade. 


#### Check and Validations Performed

* Ambari Database, ambari.properties and ambari-env backup

* Ranger Database Backup

* RangerKMS Database Backup

* Deprecated Components

* HDF Mpack

* Third Party Services

* [Hive Pre Upgrade](https://github.com/dstreev/cloudera_upgrade_utils/blob/master/hive-sre/README.md)

* Atlas backup (hbase tables)

* Ambari Auto Restart Enabled

* Database Compatibility 

* Ambari Views 

* Ambari Managed Keytabs and krb5.conf

* OS Compatibility & Service Check

### To Add 

1. Atlas backup (solr collections)

2. SSL (TBD)

### Environment Settings

To ease the launch of this script :

1. Configure access to Ambari, Ranger, RangerKMS, HiveMetastore and Oozie database.

2. Configure passwordless SSH access :
   edge node and Ambari host to take backup of ambari.properties and ambari-env. 
   egde node and Infra Solr Instances to take backup of shards 

*Example Output:* If passwordless SSH cannot be configured you need to take backup of ambari.properties and ambari-env manually.

3. Hive Client Must be Installed on the node where this script is executed

4. For unsecured cluster : (This is required for Hive Pre Upgrade check & Atlas hbase table backup)
```
- Create home directory for root user in hdfs ;
 $ su - hdfs 
 $  hdfs dfs -mkdir /user/root 
 $ hdfs dfs -chown root:root /user/root
 
- Enable acls for hdfs by configuring dfs.namenode.acls.enabled=true in custom hdfs-site.xml. Restart required services

- Set acl for root :
$ hdfs dfs -setfacl -R -m user:root:rwx /

- Execute the script prereqwrapper.sh with required parameters as described below.

```

5. For Secured Cluster : (This is required for Hive Pre Upgrade check)
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
$ sh /HDP2CDP-DC-precheck/scripts/prereqwrapper.sh --ambari=<ambari-hostname> --port=<port> --user=<ambari-admin> --password=<ambari-admin-pwd> --ssl=<yes/no> --hms=<HMS_DB_PWD>  --ranger_pwd=<RANGER_DB_PWD> --ranger_kms_pwd=<RANGERKMS_DB_PWD> --oozie_pwd=<OOZIE_DB_PWD>

-A 	| --ambari   		: Ambari Hostname
-P  | --port			: Ambari Port
-U  | --user			: Ambari Admin User
-PWD| --passwod			: Ambari Admin Password
-S  | --ssl				: SSL enabled (yes/no)
-HMS| --hms				: Hive Metasore Database Password
-RP | --ranger_pwd  	: Ranger Database Password
-RKP| --ranger_kms_pwd	: Ranger KMS Database Password
-OP | --oozie_pwd		: Ooize Database Password

For example :
# sh /HDP2CDP-DC-precheck/scripts/prereqwrapper.sh  --ambari=c3110-node1 --port=8080 --user=admin --password=amankumbare --ssl=no --hms=hadoop --hs2jdbcuri=test --ranger_pwd=rangerdba --ranger_kms_pwd=rangerkms --oozie_pwd=akshayooze

```

### Results 

- Backups are available in /HDP2CDP-DC-precheck/backup

- Outputs are available in /HDP2CDP-DC-precheck/review

- Logs are available in /HDP2CDP-DC-precheck/logs

*Feedback* For any feedback please send an email to amankumbare@cloudera.com
