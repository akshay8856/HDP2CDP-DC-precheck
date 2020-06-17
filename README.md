## HDP2.6 To CDP-DC Preupgrade Checks

This tool is to help customers to prepare and plan for upgrade from HDP to CDP-DC. Helps to get details on what actions are required before upgrading the HDP 2.x clusters.

The intent is to save the time required to prepare and perform upgrade. 


#### Check and Validations Performed

* Ambari Database, ambari.properties and ambari-env backup

* Ranger Database Backup

* RangerKMS Database Backup

* Oozie Database Backup

* Deprecated Components

* HDF Mpack

* Third Party Services

* [Hive Pre Upgrade](https://github.com/dstreev/cloudera_upgrade_utils/blob/master/hive-sre/README.md)

* Ambari Auto Restart Enabled

* Database Compatibility 

* Ambari Views 

* Ambari Managed Keytabs and krb5.conf

* OS Compatibility & Service Check

### To Add 


* Atlas backup
*  SSL (TBD)

### Environment Settings

To ease the launch of this script :

1. Configure access to Ambari, Ranger, RangerKMS, HiveMetastore and Oozie database.

2. Configure passwordless SSH access between edge node and Ambari to take backup of ambari.properties and ambari-env. If passwordless SSH cannot be configured you need to take backup of ambari.properties and ambari-env manually.

3. Hive, HDFS and Hbase Client Must be Installed on the node where this script is executed

4. For unsecured cluster : (This is required for Hive Pre Upgrade check)
```
- Create home directory for root user in hdfs ;
 $ su - hdfs 
 $ mkdir /user/root 
 $ hdfs dfs -chown root:root /user/root
 
- Enable acls for hdfs by configuring dfs.namenode.acls.enabled=true in custom hdfs-site.xml. Restart required services

- Set acl for root :
$ hdfs dfs -setfacl -R -m user:root:r-x /

- Execute the script prereqwrapper.sh

```

5. For Secured Cluster : (This is required for Hive Pre Upgrade check)
```
 - Give user readonly permission to all paths in HDFS in Ranger
 - As root user get kerberos ticket for the user for which you created policy 
 $ kinit user@realmname
 $ klist 

- Execute the script prereqwrapper.sh 
```

### How to execute ?

1. Clone this repository on the edge node

2. Run the prereqwrapper.sh script 
```
$ sh /HDP2CDP-DC-precheck/scripts/prereqwrapper.sh
```

### Results 

- Backups are available in /HDP2CDP-DC-precheck/backup

- Outputs are available in /HDP2CDP-DC-precheck/review

- Logs are available in /HDP2CDP-DC-precheck/logs

*Example Output:* I am still working on creating a consolidated view of the output to make it user friendly


![image] (https://user-images.githubusercontent.com/22625721/84717285-51fc3280-af6d-11ea-8042-858448a4a329.png)
