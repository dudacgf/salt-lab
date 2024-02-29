#!/usr/bin/env bash

{
UID_MIN=$(awk '/^s*UID_MIN/{print $2}' /etc/login.defs)
awk -F: -v UID_MIN='${UID_MIN}' '( $3 >= UID_MIN && $1 != 'nfsnobody' ) { print $1 }' /etc/passwd | xargs -n 1 chage --maxdays 365
}
