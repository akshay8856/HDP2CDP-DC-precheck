#!/bin/bash

############################################################################################################
#
#
# Author: Akshay Mankumbare
# - Premier Support Engineer
# Version: 1
# Date: 11 June 2020
############################################################################################################

host_file=$1
disk_output=$2

while IFS= read -r line
do
# This Stesp is to make sure scripts does not fail because of host key verification
# Will backup the current known_hosts file in /$user-homedir/.ssh/known_hosts.old
# Remove the host key for the specified host from /$useri-home-dir/.ssh/known_hosts.old
ssh-keygen -R $line

# Will get the latest host key from the specified hosts
ssh-keyscan $line  >> ~/.ssh/known_hosts

done < "$host_file"

sleep 5

pdsh -w^$host_file -R ssh "df -h /usr/hdp/" | grep -v Size >> $disk_output
