#!/usr/bin/env bash

{
file=/etc/authselect/$(head -1 /etc/authselect/authselect.conf | grep 'custom/')/system-auth
echo $file

if ! grep -Pq -- '^h*passwordh+(requisite|required|sufficient)h+pam_pwhistory.soh+([^#r]+h+)?remember=([5-9]|[1-9][0-9]+)b.*$' ${file}; then
    if grep -Pq -- '^h*passwordh+(requisite|required|sufficient)h+pam_pwhistory.soh+([^#r]+h+)?remember=d+b.*$' ${file}; then
        sed -ri 's/^s*(passwords+(requisite|required|sufficient)s+pam_pwhistory.sos+([^#r]+s+)?)(remember=S+s*)(s+.*)?$/1 remember=5 5/' $file
    elif grep -Pq -- '^h*passwordh+(requisite|required|sufficient)h+pam_pwhistory.soh+([^#r]+h+)?.*$' ${file}; then
        sed -ri '/^s*passwords+(requisite|required|sufficient)s+pam_pwhistory.so/ s/$/ remember=5/' $file
    else
        sed -ri '/^s*passwords+(requisite|required|sufficient)s+pam_unix.so/i password required pam_pwhistory.so remember=5 use_authtok' $file
    fi
fi

if ! grep -Pq -- '^h*passwordh+(requisite|required|sufficient)h+pam_unix.soh+([^#r]+h+)?remember=([5-9]|[1-9][0-9]+)b.*$' ${file}; then
    if grep -Pq -- '^h*passwordh+(requisite|required|sufficient)h+pam_unix.soh+([^#r]+h+)?remember=d+b.*$' ${file}; then
        sed -ri 's/^s*(passwords+(requisite|required|sufficient)s+pam_unix.sos+([^#r]+s+)?)(remember=S+s*)(s+.*)?$/1 remember=5 5/' $file
    else
        sed -ri '/^s*passwords+(requisite|required|sufficient)s+pam_unix.so/ s/$/ remember=5/' $file
    fi
fi

authselect apply-changes
}


