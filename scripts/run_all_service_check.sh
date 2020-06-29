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

echo -e "\nCluster name to run service check on is: $cluster_name"
 
running_components=$(curl -s -u $LOGIN:$PASSWORD --insecure "$protocol://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/services?fields=ServiceInfo/service_name" | python -mjson.tool | perl -ne '/"service_name":.*?"(.*?)"/ && print "$1\n"')
if [ -z "$running_components" ]; then
    exit
fi
#echo "There are following running services :
#$running_components"
 
post_body=
for s in $running_components; do
    if [ "$s" == "ZOOKEEPER" ]; then
        post_body="{\"RequestInfo\":{\"context\":\"$s Service Check\",\"command\":\"${s}_QUORUM_SERVICE_CHECK\"},\"Requests/resource_filters\":[{\"service_name\":\"$s\"}]}"
 
    else
        post_body="{\"RequestInfo\":{\"context\":\"$s Service Check\",\"command\":\"${s}_SERVICE_CHECK\"},\"Requests/resource_filters\":[{\"service_name\":\"$s\"}]}"
    fi
    curl -s -u $LOGIN:$PASSWORD --insecure -H "X-Requested-By:X-Requested-By" -X POST --data "$post_body"  "$protocol://$AMBARI_HOST:$PORT/api/v1/clusters/$cluster_name/requests"

echo -e "Please check ambariUI to confirm the status of ServiceCheck"
done

