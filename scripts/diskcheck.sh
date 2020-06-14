#!/bin/bash
# 
# diskcheck.sh : A simple shell script that take action when occupied disk reach a threshold
# Version: 2.0 (stable for use in Production)
# Author: Christophe Casalegno / Brain 0verride
# Website: https://scalarx.com
# Twitter: https://twitter.com/ScalarTech
# Email: christophe.casalegno@scalarx.com
# Note: N/A

alert_threshold=90 #You will be alerted if your occupied space is more or equal than threshold


# Hostname
host=$(hostname -f)

i=0

for disk in $(df |grep dev |grep -v tmpfs |grep -v udev| awk -F" " '{print $1}' | cut -d/ -f3)
    do
        space_use=$(df | grep "$disk" | awk -F" " '{print $5}' | cut -d% -f1)

        if [ "$space_use" -gt "$alert_threshold" ]
            
            then

                i=$((i + 1))
                over_threshold["$i"]="$disk"
        fi
    done

        if [ ${#over_threshold[*]} -gt 0 ]
            
            then
                
                echo "Disk space over threshold on $host"
                echo "Disks with space problem with more than $alert_threshold% occupied space"
               

                for disk in ${over_threshold[*]}
                        do
                                info_disk=$(df -h | grep "$disk" | awk -F" " '{print $6, $2, $3, $4, $5}')
                                echo "- Mount point : ${info_disk[O]} - Total space : ${info_disk[1]} - Used space : ${info_disk[2]} - Free space : ${info_disk[3]} - Used space in percents : ${info_disk[4]}"
                        done


        
        fi
