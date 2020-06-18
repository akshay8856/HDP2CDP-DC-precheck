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
protocol=$5
intr=$6
now=$7
review=$8

curl -s -u $LOGIN:$PASSWORD --insecure $protocol://$AMBARI_HOST:$PORT/api/v1/views | grep href | awk -F '"' '{print $4}' | egrep -i "HIVE|HUETOAMBARI_MIGRATION|PIG|SLIDER|SMARTSENSE|Storm_Monitoring|TEZ" > $intr/files/views-$now.txt

while IFS= read -r line
do
curl -s -u $LOGIN:$PASSWORD --insecure $line | grep href | grep version | awk -F '"' '{print $4}' >> $intr/files/viewversion-$now.txt
done < "$intr/files/views-$now.txt"

echo -e "Please remove below views before upgrade:\n" >> $review/servicecheck/ambariview-$now.out
echo "COMPONENT	      VIEW-INSTANCE"  >> $review/servicecheck/ambariview-$now.out

while IFS= read -r line
do
curl -s -u $LOGIN:$PASSWORD --insecure $line/instances | grep href | awk -F '"' '{print $4}' | grep -w "$line/instances/.*" | awk -F '/' '{{OFS = "\t"}; print $7, $11}' >> $review/servicecheck/ambariview-$now.out

done < "$intr/files/viewversion-$now.txt"

echo -e "\nPlease refer https://docs.cloudera.com/cdp/latest/upgrade-hdp/topics/amb-changes-services-views.html for more information" >> $review/servicecheck/ambariview-$now.out



