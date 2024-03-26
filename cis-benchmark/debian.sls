########
#### 
# CIS BENCHMARKS DEBIAN 12 SERVER LEVEL 1
####
# PDF: https://learn.cisecurity.org/l/799323/2024-02-21/4thxkw
#

####
#### 1. Initial Setup
####

### 1.1 File System Configuration
{% include "cis-benchmark/os_agnostic/1_1_file_system.sls" %}

### 1.2 

### 1.3.1 Configure AppArmor
## 1.3.1.1 Ensure AppArmor is installed
install apparmor:
  pkg.installed:
    - pkgs: ['apparmor', 'apparmor-utils']

## 1.3.1.2 Ensure AppArmor is enabled in the bootloader configuration
/etc/default/grub:
  file.line:
    - after: '^GRUB_CMDLINE_LINUX=""$'
    - content: 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX apparmor=1 security=apparmor"'
    - mode: insert
    - unless: grep 'GRUB_CMDLINE_LINUX="$GRUB_CMDLINE_LINUX apparmor=1 security=apparmor"'

apparmor-update-grub:
  cmd.run:
    - name: update-grub
    - onchanges:
      - file: /etc/default/grub

## 1.3.1.3 Ensure all AppArmor Profiles are in enforce or complain mode
## 1.3.1.4 Ensure all AppArmor Profiles are enforcing
{%- if pillar.cis_parms.apparmor | default('enforced') == 'enforced' %}
# enforce
aa-enforce /etc/apparmor.d/*: cmd.run
{%- else %}
# complain
aa-complain /etc/apparmor.d/*: cmd.run
{%- endif %}

### 1.3 Filesystem Integrity Checking
## 1.3.1/1.3.2 Instalação do pacote aide e assegurar que roda regularmente
{% include 'basic_services/aide.sls' %}

### 1.4 Configure bootloader
## 1.4.1 Ensure bootloader password is set
## I will not implement this options because it needs an operator present at every boot
## this commented state would create a superuser with values from pillar
{#
/etc/grub.d/10-bootpw:
  file.managed:
    - mode: 0755
    - contents: |
          #!/bin/bash
          USER={{ pillar['cis_parms']['user'] }}
          PASSWORD={{ pillar['cis_parms']['password'] }}
          PW=`echo -e "$PASSWORD\n$PASSWORD\n" | grub-mkpasswd-pbkdf2 | tail -n 1 | sed -- 's/^.*password is //'`
          cat <<EOF
          set superusers=$USER
          password_pbkdf2 boot_root $PW
          EOF
#}

## 1.4.2 Ensure permissions on bootloader config are configured
grubreadonly:
  cmd.run:
    - name: sed -ri 's/chmod\s+[0-7][0-7][0-7]\s+\$\{grub_cfg\}\.new/chmod 400 ${grub_cfg}.new/' /usr/sbin/grub-mkconfig
    - unless: grep -E '^\s*chmod\s+400\s+\$\{grub_cfg\}\.new' /usr/sbin/grub-mkconfig

/boot/grub/grub.cfg:
  file.managed:
    - user: root
    - group: root
    - mode: 0400

## 1.4.3 Ensure authentication required for single user mode 
### I will not implement this option because the atacker would need physical access to the host
### or network access to its virtual host to gain single user access to the server

### 1.5 Configure Additional Process Hardening
## 1.5.1 Ensure address space layout randomization (ASLR) is enabled
/etc/sysctl.d/60-kernel.conf:
  file.managed:
    - contents: |
        kernel.randomize_va_space = 2
        kernel.yama.ptrace_scope = 1

## 1.5.3 Ensure core dumps are restricted
/etc/security/limits.d/60-restrict-core-dumps:
  file.managed:
    - contents: |
          hard core 0

/etc/sysctl.d/61-restric-core-dumps.conf:
  file.managed:
    - contents: | 
          fs.suid_dumpable = 0

/etc/systemd/coredump.conf:
  file.managed:
    - contents: | 
          [Coredump]
          Storage=none
          ProcessSizeMax=0
    - onlyif: systemctl is-enabled coredump.service

## 1.5.4 Ensure prelink is not installed 
prelink: pkg.purged

### 1.6 Command Line Warning Banners
{% include "cis-benchmark/os_agnostic/1_7_banners.sls" %}

### 1.8 Gnome Display Manager
{% include "cis-benchmark/os_agnostic/1_8_gnome.sls" %}

### 1.9 Ensure updates, patches, and additional security software are installed
{% include 'utils/update_all.sls' %}

####
#### 2. SERVICES
####

### 2.1 Special Purpose Services
{% include "cis-benchmark/os_agnostic/2_1_services.sls" %}

### 2.2 Service Clients

## 2.2.1 Ensure NIS Client is not installed
## já executado em 2.2.14

## 2.2.2 Ensure rsh client is not installed
rsh-client: pkg.purged

## 2.2.3 Ensure talk client is not installed
talk: pkg.purged

## 2.2.4 Ensure telnet client is not installed
telnet: pkg.purged

## 2.2.5 Ensure LDAP client is not installed 
ldap-utils: pkg.purged

## 2.2.6 Ensure RPC is not installed 
# already done at 2_1_services
#rpcbind: pkg.purged

### 2.3 Configure Time Synchronization

## 2.3.1.1 Ensure a single time synchronization daemon is in use
## 2.3.2 Configure chrony
{% include 'basic_services/chrony.sls' %}

# remainings 2.3.xxxx directives would setup other time servicess (NTP or systemd-timesyncd)


####
#### Network Configuration
####
{% include "cis-benchmark/os_agnostic/3_network_configuration.sls" %}

####
#### 4 Logging and Auditing
####

### 4.1 audit
{% include "basic_services/auditd.sls" %}

### 4.2 LOG. Pillar will determine whether one of journald/rsyslog/syslog-ng will be used
{% if pillar['logger'] | default('journald') == 'journald' %}
{% include "basic_services/journald.sls" %}
{% elif pillar['logger'] == 'rsyslogd' %}
{% include "basic_services/rsyslog.sls" %}
{% elif pillar['logger'] == 'rsyslogd' %}
{% include "basic_services/syslog-ng.sls" %}
{% endif %}

####
#### 5 Access, Authentication and Authorization
####

### 5.1 CRON/AT
## 5.1.1 Ensure cron daemon is enabled and running
cron:
  service.running:
    - enable: True

## 5.1.2 Ensure permissions on /etc/crontab are configured
## 5.1.3 Ensure permissions on /etc/cron.hourly are configured
## 5.1.4 Ensure permissions on /etc/cron.daily are configured
## 5.1.5 Ensure permissions on /etc/cron.weekly are configured
## 5.1.6 Ensure permissions on /etc/cron.monthly are configured
## 5.1.7 Ensure permissions on /etc/cron.d are configured
## 5.1.8 Ensure cron is restricted to authorized users
'chmod 600 /etc/crontab': cmd.run
'chmod 700 /etc/cron.*': cmd.run

## 5.1.8 Ensure cron is restricted to authorized users
/etc/cron.deny: file.absent
/etc/cron.allow: 
  file.managed:
    - user: root
    - group: root
    - mode: 0600
    - contents: |
          root

## 5.1.9 Ensure at is restricted to authorized users
/etc/at.deny: file.absent
/etc/at.allow:
  file.managed:
    - user: root
    - group: root
    - mode: 0600
    - contents: |
          root

### 5.2 Configure SSH Server
### already done in environment.sshd
{#% include "environment/sshd.sls" %#}

### 5.3 Configure privilege escalation (SUDO/PKEXEC)
### already done in environment.users
{#% include "environment/users/sudo_manage.sls" %#}

### 5.4 Configure PAM
{% include "cis-benchmark/pam/ubuntu.sls" %}

### 5.5 User Accounts and Environment
{% include "cis-benchmark/os_agnostic/5_5_user_accounts.sls" %}

### 6.1 file permissions
{% include "cis-benchmark/os_agnostic/6_file_permissions.sls" %}


