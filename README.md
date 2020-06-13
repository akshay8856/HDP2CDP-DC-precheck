# HDP2CDP-DC-precheck
HDP2.6.5 to CDP-DC pre checks

- As of now works only with non kerberized clusters

Before you run this script please make sure you have givent root user all the permisison for HDFS dirs :
1. From Ambari : add dfs.namenode.acls.enabled=true in custom hdfs-site.xml
2. Give Acl's :
$  su - hdfs ; 
$  hdfs dfs -setfacl -R -m user:root:r-x /


To execute this script :

Note: Run as root user

$ yum install git -y ; cd / ; git clone https://github.com/akshay8856/HDP2CDP-DC-precheck.git ; sleep 5 ;sh /HDP2CDP-DC-precheck/scripts/prereqwrapper.sh
