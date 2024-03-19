########
#### 
# CIS Red Hat Enterprise Linux 9 Benchmark v1.0.0 SERVER LEVEL 1
####
# PDF: https://learn.cisecurity.org/l/799323/2022-11-30/4ccvd7
#

####
#### 1. Initial Setup
####

### 1.1 File System Configuration
{% include "cis-benchmark/os_agnostic/1_1_file_system.sls" %}

### 1.2 Configure Software Updates. já executado no State packages.sls

### 1.3 Filesystem Integrity Checking
## 1.3.1/1.3.2 Instalação do pacote aide e assegurar que roda regularmente
{% include 'basic_services/aide.sls' %}

## 1.4.1 Ensure bootloader password is set
## 1.4.2 Ensure permissions on bootloader config are configured
## pillar.cis_parms.grub_boot_password must be previously generated with the command grub2-mkpasswd-pbkdf2
protect grub config:
  file.managed:
    - user: root
    - group: root
    - mode: 0400
    - names: 
      - /boot/grub2/grub.cfg
      - /boot/grub2/grubenv
      - /boot/grub2/user.cfg:
        - contents: GRUB2_PASSWORD={{ pillar.cis_parms.grub_boot_password }}

## 1.4.3 Ensure authentication required for single user mode 
### I will not implement this option because the atacker would need physical access to the host
### or network access to its virtual host to gain single user access to the server

# finalize grub configuration
/usr/sbin/grub2-mkconfig: cmd.run

## 1.5.1 Ensure core dump storage is disabled 
## 1.5.2 Ensure core dump backtraces are disabled
/etc/systemd/coredump.conf:
  file.managed:
    - contents: | 
          [Coredump]
          Storage=none
          ProcessSizeMax=0

## 1.5.3 Ensure address space layout randomization (ASLR) is enabled
/etc/sysctl.d/60-kernel.conf:
  file.managed:
    - contents: |
        kernel.randomize_va_space = 2

### 1.6.1 Configure SELinux
## 1.6.1.1 Ensure SELinux is installed
libselinux: pkg.installed

## 1.6.1.2 Ensure SELinux is enabled in the bootloader configuration
enforce selinux:
  cmd.script:
    - source: salt://cis-benchmark/scripts/selinux_on_grub2.sh
    - cwd: /root

## 1.6.1.3 Ensure SELinux type are targeted
## 1.6.1.4 Ensure SELinux mode is not disabled
## 1.6.1.5 Ensure SElinux mode is enforced
/etc/selinux/config:
  file.managed:
    - contents: | 
          SELINUX=enforcing
          SELINUXTYPE=targeted

## salt-minion et all would run unconfined
'chcon system_u:object_r:rpm_exec_t:s0 /usr/bin/salt-minion': cmd.run
'chcon system_u:object_r:rpm_exec_t:s0 /usr/bin/salt-call': cmd.run
'chcon system_u:object_r:rpm_exec_t:s0 /usr/bin/salt-pip': cmd.run
'chcon system_u:object_r:rpm_exec_t:s0 /usr/bin/salt-proxy': cmd.run

## 1.6.1.7 Ensure SETroubleshoot is not installed 
settroubleshoot: pkg.removed

## 1.6.1.8 Ensure the MCS Translation Service (mcstrans) is not installed
mcstrans: pkg.removed

### 1.7 Command Line Warning Banners
{% include "cis-benchmark/os_agnostic/1_7_banners.sls" %}

### 1.8 Gnome Display Manager
{% include "cis-benchmark/os_agnostic/1_8_gnome.sls" %}

### 1.9 Ensure updates, patches, and additional security software are installed
{% include 'utils/update_all.sls' %}

### 1.10 Ensure system-wide crypto policy is not legacy
/etc/crypto-policies/config:
  file.managed:
    - contents: 'DEFAULT'

update-crypto-policies:
  cmd.run:
    - watch:
      - file: /etc/crypto-policies/config

####
#### 2. SERVICES
####

### 2.1 Configure Time Synchronization

## 2.1.1.1 Ensure a single time synchronization daemon is in use
## 2.1.2 Configure chrony
{% include 'basic_services/chrony.sls' %}

# resto de 2.1.xxxx configuraria os outros serviços (NTP ou systemd-timesyncd)
# não será configurado pois usamos chrony

### 2.2 Special Purpose Services

## 2.2.2 Ensure Avahi Server is not installed
avahi: pkg.purged

## 2.2.4 Ensure DHCP Server is not installed 
{% if not 'dhcp-server' in pillar['services'] | default(False) %}
dhcp-server: pkg.purged
{% endif %}

## 2.2.5 Ensure DNS Server is not installed 
bind: pkg.purged

## 2.2.6 Ensure VSFTP Server is not installed
vsftpd: pkg.purged

## 2.2.7 Ensure TFTP Server is not installed
tftp-server: pkg.purged

## 2.2.8 Ensure a web server is not installed
{% if not 'apache' in pillar['services'] | default(False) %}
purge webservers:
  pkg.purged:
    - pkgs: ['httpd', 'nginx']
{% endif %}

## 2.2.9 Ensure IMAP and POP3 server is not installed 
purge pop imap:
  pkg.purged:
    - pkgs: ['dovecot', 'cyrus-imapd']

## 2.2.5 Ensure LDAP server is not installed 
{% if not 'ldap-server' in pillar['services'] | default(False) %}
ldapd: pkg.purged
{% endif %}

## 2.2.10 Ensure Samba is not installed
samba: pkg.purged

## 2.2.11 Ensure HTTP Proxy Server is not installed 
{% if not 'squid' in pillar['services'] | default(False) %}
squid: pkg.purged
{% endif %}

## 2.2.12 Ensure SNMP Server is not installed 
{% if not 'snmpd' in pillar['basic_services'] | default(False) %}
net-snmp: pkg.purged
{% endif %}

## 2.2.13 Ensure telnet-server is not installed
telnet-server: pkg.purged

## 2.2.14 Ensure dnsmasq is not installed
dnsmasq: pkg.purged

## 2.2.15 Ensure mail transfer agent is configured for local-only mode
/etc/postfix/main.cf:
  file.managed:
    - pattern: 'inet_interface.*=.*'
    - repl: 'inet_interface=loopback-only'
    - onlyif:
      - fun: pkg.info_installed
        args: ['postfix']

postfix.service:
  service.running:
    - restart: true
    - watch:
      - file: /etc/postfix/main.cf
    - onlyif:
      - fun: pkg.info_installed
        args: ['postfix']

## 2.2.16 Ensure NFS is not installed 
systemctl --now mask nfs-server: cmd.run

nfs-utils: pkg.purged

## 2.2.17 Ensure rpcbind is not installed or the rpcbind services are masked
systemctl --now mask rpcbind.service: cmd.run
systemctl --now mask rpcbind.socket: cmd.run

rpcbind: pkg.purged

## 2.2.18 Ensure rsync service is either not installed or masked
rsyncd.service:
  service.dead:
    - enable: False

rsync-daemon: pkg.purged

### 2.3 Service Clients

## 2.3.1 Ensure telnet client is not installed
telnet: pkg.purged

## 2.3.2 Ensure LDAP client is not installed 
openldap-clients: pkg.purged

## 2.3.3 Ensure TFTP client is not installed 
tftp: pkg.purged

## 2.3.4 Ensure FTP client is not installed
ftp: pkg.purged

## 2.3.5 Ensure rsh client is not installed (extra)
rsh: pkg.purged

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
{% if grains['os_family'] == 'RedHat' %} # redhat comes with rsyslog installed
{% include "basic_services/rsyslog.sls" %}
{% endif %}

####
#### 5 Access, Authentication and Authorization
####

### 5.1 CRON/AT
## 5.1.1 Ensure cron daemon is enabled and running
crond:
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
{% include "environment/sshd.sls" %}

### 5.3 Configure privilege escalation (SUDO/PKEXEC)
{% include "environment/users/sudo_manage.sls" %}

### 5.4 Configure PAM
{% include "cis-benchmark/pam/init.sls" %}

### 5.5 User Accounts and Environment
{% include "cis-benchmark/os_agnostic/5_5_user_accounts.sls" %}

### 6.1 file permissions
{% include "cis-benchmark/os_agnostic/6_file_permissions.sls" %}

### CIS EXTRA. ajusta conta root
{% include "environment/users/root_manage.sls" %}

