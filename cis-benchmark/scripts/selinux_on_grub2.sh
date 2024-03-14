#!/usr/bin/env bash

## 1.6.1.2 Ensure SELinux is enabled in the bootloader configuration
if grubby --info=ALL | grep -Po '(selinux|enforcing)=0\b'; then
    grubby --update-kernel ALL --remove-args "selinux=0 enforcing=0"

    grep -Prsq -- '\h*([^#\n\r]+\h+)?kernelopts=([^#\n\r]+\h+)?(selinux|enforcing)=0\b' /boot/grub2 /boot/efi && \
        grub2-mkconfig -o "$(grep -Prl -- '\h*([^#\n\r]+\h+)?kernelopts=([^#\n\r]+\h+)?(selinux|enforcing)=0\b' /boot/grub2 /boot/efi)";
else
    echo '-- no options found';
fi

