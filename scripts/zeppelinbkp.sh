#!/bin/bash
############################################################################################################
#
#
# Author: Akshay Mankumbare
# - Premier Support Engineer
# Version: 1
# Date: 11 June 2020
############################################################################################################

config=$1
iskerberos=$2

zeppelin_host=`grep zeppelin_host $config | awk -F'=' '{print $2}'`
zeppelin_user=`grep zeppelin_user $config | awk -F'=' '{print $2}'`
zeppelin_conf=`grep zeppelin_conf $config | awk -F'=' '{print $2}'`
zeppelin_notebook=`grep zeppelin_notebook $config | awk -F'=' '{print $2}'`
zeppelin_keytab=`grep zeppelin_keytab $config | awk -F'=' '{print $2}'`
zeppelin_princ=`grep zeppelin_princ $config | awk -F'=' '{print $2}'`
zeppelin_storage=`grep zeppelin_storage $config | awk -F'=' '{print $2}'`


# This Stesp is to make sure scripts does not fail because of host key verification
# Will backup the current known_hosts file in /$user-homedir/.ssh/known_hosts.old
# Remove the host key for the specified host from /$useri-home-dir/.ssh/known_hosts.old
ssh-keygen -R $zeppelin_host

# Will get the latest host key from the specified hosts
ssh-keyscan $zeppelin_host  >> ~/.ssh/known_hosts

if [ -z "$iskerberos" ];then

  echo -e "Creating direcotry for backup: /var/lib/zeppelin/$zeppelin_conf /var/lib/zeppelin/$zeppelin_notebook on $zeppelin_host\n"
  ssh $zeppelin_host "sudo -u $zeppelin_user mkdir -p /var/lib/zeppelin/$zeppelin_conf /var/lib/zeppelin/$zeppelin_notebook"
  echo -e "Taking backup of Notebook HDFS directory /user/zeppelin/$zeppelin_notebook/ \n"
  ssh $zeppelin_host "sudo -u $zeppelin_user hdfs dfs -get /user/zeppelin/$zeppelin_notebook/* /var/lib/zeppelin/$zeppelin_notebook"
  echo -e "Taking backup of interpreter.json and notebook-authorization.json from HDFS directory /user/zeppelin/$zeppelin_conf \n"
  ssh $zeppelin_host "sudo -u $zeppelin_user hdfs dfs -get /user/zeppelin/$zeppelin_conf/interpreter.json /user/zeppelin/$zeppelin_conf/notebook-authorization.json /var/lib/zeppelin/$zeppelin_conf"

else
  echo -e "Creating direcotry for backup: /var/lib/zeppelin/$zeppelin_conf /var/lib/zeppelin/$zeppelin_notebook on $zeppelin_host\n"
  ssh $zeppelin_host "sudo -u $zeppelin_user mkdir -p /var/lib/zeppelin/$zeppelin_conf /var/lib/zeppelin/$zeppelin_notebook"
  echo -e "Get Kerberos ticket for zeppelin"
  ssh $zeppelin_host "sudo -u $zeppelin_user kinit -kt $zeppelin_keytab $zeppelin_princ"
  echo -e "Taking backup of Notebook HDFS directory /user/zeppelin/$zeppelin_notebook/ \n"
  ssh $zeppelin_host "sudo -u $zeppelin_user hdfs dfs -get /user/zeppelin/$zeppelin_notebook/* /var/lib/zeppelin/$zeppelin_notebook"
  echo -e "Taking backup of interpreter.json and notebook-authorization.json from HDFS directory /user/zeppelin/$zeppelin_conf \n"
  ssh $zeppelin_host "sudo -u $zeppelin_user hdfs dfs -get /user/zeppelin/$zeppelin_conf/interpreter.json /user/zeppelin/$zeppelin_conf/notebook-authorization.json /var/lib/zeppelin/$zeppelin_conf"
fi

