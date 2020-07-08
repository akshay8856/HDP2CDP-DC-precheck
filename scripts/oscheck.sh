
#!/bin/bash
############################################################################################################
#
#
# Author: Akshay Mankumbare
# - Premier Support Engineer
# Version: 1
# Date: 11 June 2020
############################################################################################################

AMBARI_HOST=$1
PORT=$2
LOGIN=$3
PASSWORD=$4
OSOUT=$5
#SERCHK=$6
date=$6
intr=$7
protocol=$8

# Configuring cluster name
cluster_name=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARI_HOST:$PORT/api/v1/clusters"  | python -mjson.tool | perl -ne '/"cluster_name":.*?"(.*?)"/ && print "$1\n"')


# Condition to check cluster name exists
if [ -z "$cluster_name" ]; then
    exit
fi

# OS version check
echo -e "\nChecking if OS version of the nodes in cluster $cluster_name is compatible for upgrade"
curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/hosts" | grep host_name | awk -F ':' '{print $2}' |  awk -F '"' '{print $2}' >  $intr/hosts-$date.out


while IFS= read -r host
do
os=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/hosts/$host?fields=Hosts/os_type" | grep os_type | grep -v href | awk -F ':' '{print $2}' |  awk -F '"' '{print $2}')

#if [[ "$os" != "centos7" || "$os" != "Rhel7" || "$os" != "rhel7" ]]
if [ "$os" != "centos7" ] &&  [ "$os" != "Rhel7" ] && [ "$os" != "rhel7" ];
then
 echo -e "Operating system for $host is NOT compatible for upgrade" >> $OSOUT/oscheck-$date.out
else
 echo -e "Major version of Operating system for $host is compatible for upgrade" >> $OSOUT/oscheck-$date.out
fi

done < $intr/hosts-$date.out

echo -e "\nPlease refer "http://tiny.cloudera.com/oscomp" to confirm Operating System Requirements" >> $OSOUT/oscheck-$date.out
echo -e "\nOS compatibility check completed for$cluster_name. \n please check the output in $OSOUT/oscheck-$date.out"
# OS version check COMPLETED !!!!!
