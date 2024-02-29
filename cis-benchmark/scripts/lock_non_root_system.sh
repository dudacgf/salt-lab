#!/usr/bin/env bash

awk -F: '($1!='root' && $1!~/^+/ && $3<''$(awk '/^s*UID_MIN/{print $2}' /etc/login.defs)'') {print $1}' /etc/passwd | \
xargs -I '{}' passwd -S '{}' | awk '($2!='L' && $2!='LK') {print $1}' | \
   while read user; do 
     echo "$user";
   done
