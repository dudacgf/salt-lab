#!/usr/bin/env bash

awk -F: '/^[^:]+:[^!*]/{print $1}' /etc/shadow | \
    while read -r usr; do 
        echo "User: \"$usr\" last password change was \"$(chage --list $usr | grep '^Last password change' | cut -d: -f2)\""; 
    done
