#!/bin/bash
############################################################################################################
#
#
# Author: Akshay Mankumbare
# - Premier Support Engineer
# Version: 1
# Date: 11 June 2020
############################################################################################################

now=$2
out=$3/DatabaseCompatibiltiyCheck-$now.out
cdpdc=$4
props=$5/dbcomp-cdpdc$4.properties
input="$1"

### MYSQL ###
requiredvermysql=`grep mysql $props | awk -F'|' '{print $2}'`
myqlmsg=`grep mysql $props | awk -F'|' '{print $3}'`

## PSQL ###
requiredverpsql==`grep postgres $props | awk -F'|' '{print $2}'`
psqlmsg=`grep postgres $props | awk -F'|' '{print $3}'`

# Mariadb :
requiredvermaraidb=`grep mariadb  $props | awk -F'|' '{print $2}'`

while IFS= read -r line
do
  component=`echo $line | awk -F':' '{print $1}'`
  currentver=`echo $line | awk -F':' '{print $3}' | awk -F'-' '{print $1}'`
  ismariadb=`echo $line | awk -F':' '{print $3}' | awk -F'-' '{print $2}'`
  db_type=`echo $line | awk -F':' '{print $2}'`

if [ "$db_type" == "mysql" ] || [ "$db_type" == "MYSQL" ]; then
  if [ -z "$ismariadb"]; then
  requiredver=$requiredvermysql
  else
  requiredver=$requiredvermaraidb
  db_type=$ismariadb
  fi
  msg=$myqlmsg
elif [ "$db_type" == "postgres" ] || [ "$db_type" == "POSTGRES" ]; then
 requiredver=$requiredverpsql
 msg=$psqlmsg
else
  echo -e "Database compatibilty check for your databiase $db_type is not added"
fi

if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
        echo -e  "Database for $component: $db_type-$currentver is compatible for upgrade to CDP-DC"
        echo -e  "Database for $component: $db_type-$currentver: $msg\n"


        echo -e  "Database for $component: $db_type-$currentver is compatible for upgrade to CDP-DC" >> $out
        echo -e  "Database for $component: $db_type-$currentver: $msg\n" >> $out
 else
        echo -e "Database for $component: $db_type-$currentver is less than supported version $requiredver for upgrade to CDP-DC"
        echo -e  "Database for $component: $db_type-$currentver: $msg\n"

        echo -e "Database for $component: $db_type-$currentver is less than supported version $requiredver for upgrade to CDP-DC" >> $out
        echo -e  "Database for $component: $db_type-$currentver: $msg\n" >> $out
 fi

done < "$input"

echo -e "\nPlease refer http://tiny.cloudera.com/dbcomp for Database Requirements" >> $out
