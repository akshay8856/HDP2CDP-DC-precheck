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
input="$1"
while IFS= read -r line
do
  component=`echo $line | awk -F':' '{print $1}'`
  currentver=`echo $line | awk -F':' '{print $3}'`
  db_type=`echo $line | awk -F':' '{print $2}'`

if [ "$db_type" == "mysql" ] || [ "$db_type" == "MYSQL" ]; then
  requiredver="5.7"
elif [ "$db_type" == "postgres" ] || [ "$db_type" == "POSTGRES" ]; then
 requiredver="10.2"
else
  echo -e "Database compatibilty check for your databiase $db_type is not added"
fi
  
if [ "$(printf '%s\n' "$requiredver" "$currentver" | sort -V | head -n1)" = "$requiredver" ]; then
        echo -e  "Database for $component: $db_type-$currentver is compatible for upgrade to CDP-DC\n"
        echo -e  "Database for $component: $db_type-$currentver is compatible for upgrade to CDP-DC\n" >> $out
 else
        echo -e "Database for $component: $db_type-$currentver is less than supported version $requiredver for upgrade to CDP-DC\n"
        echo -e "Database for $component: $db_type-$currentver is less than supported version $requiredver for upgrade to CDP-DC\n" >> $out
 fi

done < "$input"
