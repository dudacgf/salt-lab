#!/usr/bin/env bash
export LANG=C

awk -F: '/^[^:]+:[^!*]/{print $1}' /etc/shadow | \
    while read -r usr; do 
        last_change=$(chage --list ${usr} | grep '^Last password change' | cut -d: -f2)
        echo "User: \"${usr}\" last password change was \"${last_change}\""; 

        less_30_days=$(date -d "$date -30 days" +"%Y-%m-%d")
        echo "setting last password change of ${usr} to ${less_30_days}"
        chage -d ${less_30_days} ${usr} 

    done


