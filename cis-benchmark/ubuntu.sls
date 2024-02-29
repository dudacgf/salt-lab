########
#### 
# CIS BENCHMARKS UBUNTU 20.04/21.04 SERVER LEVEL 1
####
# PDF: https://learn.cisecurity.org/l/799323/2021-04-01/41hcb
#

####
#### 1. Initial Setup
####

### 1.1 File System Configuration

## 1.1.1 Desabilita diversos sistemas de arquivos nunca utilizados
/etc/modprobe.d/cramfs.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install cramfs /bin/true

/etc/modprobe.d/freevxfs.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install freevxfs /bin/true

/etc/modprobe.d/jffs2.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install jffs2 /bin/true

/etc/modprobe.d/hfs.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install hfs /bin/true

/etc/modprobe.d/hfsplus.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install hfsplus /bin/true

/etc/modprobe.d/squashfs.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install squashfs /bin/true

/etc/modprobe.d/udf.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install udf /bin/true

## 1.1.2/1.1.3/1.1.4/1.1.5. Partição separada para o /tmp
## 1.1.6/1.1.7/1.1.8/1.1.9  Partição separada para /dev/shm
# 1.1.11/1.1.12/1.1.13/1.1.14  Partição Separada para o /var/tmp
/etc/fstab:
  file.append:
    - text: |
        tmpfs    /tmp        tmpfs	defaults,noexec,nodev,nosuid,size=2G	0	0
        tmpfs    /dev/shm    tmpfs	defaults,noexec,nodev,nosuid,size=2G	0	0
        tmpfs    /var/tmp    tmpfs	defaults,noexec,nodev,nosuid,size=2G	0	0

# 1.1.10 Partição Separada para o /var. Não será feito aqui

# 1.1.15 Partição Separada para o /var/log. Não será feito aqui

# 1.1.16 Partição Separada para o /var/log/audit. Não será feito aqui

# 1.1.17 Partição Separada para o /home. Não será feito aqui

# 1.1.18 nodev option na partição /home. Não será feito aqui

# 1.1.19/1.1.20/10.1.21 nosuid/nodev/noexec/nosuid para o /home. Não será feito aqui
nosuid_home:
  file.replace:
    - name: /etc/fstab
    - pattern: '\/home.*ext4.*defaults'
    - repl: '/home   	ext4	rw,nodev,noexec,nosuid'

# 1.1.22 Ensure sticky bit is set on all world-writable directories. Não entendi. Vou estudar mais

# 1.1.23 Desabilita o serviço autofs para montagem automática de mídia removível
autofs:
  service.disabled

# 1.1.24 Disable USB Storage
/etc/modprobe.d/usb_storage.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents: |
          install usb-storage /bin/true

## 1.2 Configure Software Updates. já executado no State packages.sls

# 1.3 Filesystem Integrity Checking

## 1.3.1/1.3.2 Instalação do pacote aide e assegurar que roda regularmente
{% include 'basic_services/aide.sls' %}

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

## 1.5.1 Ensure address space layout randomization (ASLR) is enabled
/etc/sysctl.d/60-kernel.conf:
  file.managed:
    - contents: |
        kernel.randomize_va_space = 2

## 1.5.2 Ensure prelink is not installed 
prelink: pkg.purged


## 1.5.3 Ensure Automatic Error Reporting is not enabled
apport.service:
  service.dead:
    - enable: False

/etc/default/apport:
  file.replace:
    - pattern: '^enabled=1$'
    - repl: 'enabled=0'
    
## 1.5.4 Ensure core dumps are restricted
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
          Storage=none
          ProcessSizeMax=0
    - onlyif: systemctl is-enabled coredump.service

### 1.6.1 Configure AppArmor
## 1.6.1.1 Ensure AppArmor is installed
apparmor: pkg.installed

## 1.6.1.2 Ensure AppArmor is enabled in the bootloader configuration
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

## 1.6.1.3 Ensure all AppArmor Profiles are in enforce or complain mode
## 1.6.1.4 Ensure all AppArmor Profiles are enforcing
# essa eu não entendi muito bem as consequências, vou pular até poder testar
# enforce
#aa-enforce /etc/apparmor.d/*: cmd.run
# complain
#aa-complain /etc/apparmor.d/*: cmd.run

### 1.7 Command Line Warning Banners
## 1.7.1 Ensure message of the day is configured properly (remove it)
## 1.7.4 Ensure permissions on /etc/motd are configured
# já removido, não será feito
/etc/motd: file.absent

## 1.7.2 Ensure local login warning banner is configured properly 
## 1.7.5 Ensure permissions on /etc/issue are configured
/etc/issue: 
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - contents: | 
          Authorized uses only. All activity may be monitored and reported.

## 1.7.3 Ensure remote login warning banner is configured properly
## 1.7.6 Ensure permissions on /etc/issue.net are configured
/etc/issue.net: 
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - contents: | 
          Authorized uses only. All activity may be monitored and reported.

### 1.8 Gnome Display Manager
{% if not pillar['apps']['gnome-desktop'] | default(False) %}
## 1.8.1 Ensure GNOME Display Manager is removed 
gdm3: pkg.purged
xserver-xorg: pkg.purged
pkg.autoremove: module.run
{% else %}
## 1.8.2 Ensure GDM login banner is configured 
/etc/dconf/profile/gdm:
  file.managed:
    - contents: |
          user-db:user
          system-db:gdm
          file-db:/usr/share/gdm/greeter-dconf-defaults

/etc/dconf/db/gdm.d/01-banner-message:
  file.managed:
    - makedirs: True
    - contents:
          [org/gnome/login-screen]
          banner-message-enable=true
          banner-message-text='Type the banner message here.'

## 1.8.3 Ensure GDM disable-user-list option is enabled 
/etc/dconf/db/gdm.d/00-login-screen:
  file.managed:
    - makedirs: True
    - contents:
          [org/gnome/login-screen]
          disable-user-list=true

## 1.8.4 Ensure GDM screen locks when the user is idle
/etc/dconf/profile/user:
  file.managed:
    - contents: |
          user-db:user
          system-db:local

/etc/dconf/db/local.d/00-screensaver:
  file.managed:
    - makedirs: True
    - contents: |
          [org/gnome/desktop/session]
          idle-delay=uint32 900
          [org/gnome/desktop/screensaver]
          lock-delay=uint32 5

## 1.8.5 Ensure GDM screen locks cannot be overridden
/etc/dconf/db/local.d/locks/00-screensaver:
  file.managed:
    - makedirs: True
    - contents: |
          /org/gnome/desktop/screensaver/idle-delay
          /org/gnome/desktop/screensaver/lock-delay

## 1.8.6 Ensure GDM automatic mounting of removable media is disabled
## 1.8.8 Ensure GDM autorun-never is enabled
/etc/dconf/db/local.d/00-media-automount:
  file.managed:
    - makedirs: True
    - contents: |
          [org/gnome/desktop/media-handling]
          automount=false
          automount-open=false
          autorun-never=true

## 1.8.7 Ensure GDM disabling automatic mounting of removable is not overriden
## 1.8.9 Ensure GDM autorun-never is not overridden
/etc/dconf/db/local.d/locks/00-media-automount:
  file.managed:
    - makedirs: True
    - contents: |
          /org/gnome/desktop/media-handling/automount
          /org/gnome/desktop/media-handling/automount-open
          /org/gnome/desktop/media-handling/automount-open
#gsettings set org.gnome.desktop.media-handling automount false: cmd.run

## 1.8.10 Ensure XDCMP is not enabled 
/etc/gdm3/custom.conf:
  file.replace:
    - pattern: '(\[xdmcp\]\n)Enable.*=.*true'
    - repl: '\1Enable=false'

## updates dconf
dconf update: cmd.run

# pegando carona no fato de que o gnome não é desejado nesse sistema e antecipando
# a remoçao total do X 
## 2.2.1 Ensure X Window System is not installed
xserver-xorg: pkg.purged

## 2.2.3 Ensure CUPS is not installed 
cups: pkg.purged

{% endif %}

### 1.9 Ensure updates, patches, and additional security software are installed
{% include 'utils/update_all.sls' %}

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
avahi-daemon: pkg.purged

## 2.2.4 Ensure DHCP Server is not installed 
{% if not 'dhcp-server' in pillar['services'] | default(False) %}
isc-dhcp-server: pkg.purged
{% endif %}

## 2.2.5 Ensure LDAP server is not installed 
{% if not 'ldap-server' in pillar['services'] | default(False) %}
ldapd: pkg.purged
{% endif %}

## 2.2.6 Ensure NFS is not installed 
nfs-kernel-server: pkg.purged

## 2.2.7 Ensure DNS Server is not installed 
{% if not 'bind9' in pillar['services'] | default(False) %}
bind9: pkg.purged
{% endif %}

## 2.2.8 Ensure FTP Server is not installed
vsftpd: pkg.purged

## 2.2.9 Ensure HTTP server is not installed 
{% if not 'apache' in pillar['services'] | default(False) %}
apache2: pkg.purged
{% endif %}

## 2.2.10 Ensure IMAP and POP3 server are not installed
apt purge dovecot-imapd dovecot-pop3d: cmd.run

## 2.2.11 Ensure Samba is not installed
samba: pkg.purged

## 2.2.12 Ensure HTTP Proxy Server is not installed 
{% if not 'squid' in pillar['services'] | default(False) %}
squid: pkg.purged
{% endif %}

## 2.2.13 Ensure SNMP Server is not installed 
{% if not 'snmpd' in pillar['basic_services'] | default(False) %}
snmp: pkg.purged
{% endif %}

## 2.2.14 Ensure NIS Server is not installed
nis: pkg.purged

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

## 2.2.16 Ensure rsync service is either not installed or masked
rsync.service:
  service.dead:
    - enable: False

### 2.3 Service Clients

## 2.3.1 Ensure NIS Client is not installed
## já executado em 2.2.14

## 2.3.2 Ensure rsh client is not installed
rsh-client: pkg.purged

## 2.3.3 Ensure talk client is not installed
talk: pkg.purged

## 2.3.4 Ensure telnet client is not installed
telnet: pkg.purged

## 2.3.5 Ensure LDAP client is not installed 
ldap-utils: pkg.purged

## 2.3.6 Ensure RPC is not installed 
rpcbind: pkg.purged


####
#### Network Configuration
####

### 3.1 Disable unused network protocols and devices

## 3.1.1 Ensure system is checked to determine if IPv6 is enabled
## will not use ipv6. it will be disabled via sysctl
/etc/sysctl.d/62-ipv6-disable.conf:
  file.managed:
    - contents: |
          net.ipv6.conf.all.disable_ipv6 = 1
          net.ipv6.conf.default.disable_ipv6 = 1

## 3.1.2 Ensure wireless interfaces are disabled
disable wireless:
  cmd.script:
    - source: salt://cis-benchmark/scripts/wireless-off.sh
    - cwd: /root

### 3.2 Network Parameters (Host)

## 3.2.1 Ensure packet redirect sending is disabled
/etc/sysctl.d/63_disable_packets_redirect.conf:
  file.managed:
    - contents: |
          net.ipv4.conf.all.send_redirects = 0
          net.ipv4.conf.default.send_redirects = 0

## 3.2.2 Ensure IP forwarding is disabled 
/etc/sysctl.d/64_disable_ip_forward.conf:
  file.managed:
    - contents: |
          net.ipv4.ip_forward = 0
          net.ipv6.conf.all.forwarding = 0

### 3.3 Network Parameters (Host and Router)

## 3.3.1 Ensure source routed packets are not accepted
/etc/sysctl.d/65_disable_source_routed_packets.conf:
  file.managed:
    - contents: |
          net.ipv4.conf.all.accept_source_route = 0
          net.ipv4.conf.default.accept_source_route = 0
          net.ipv6.conf.all.accept_source_route = 0
          net.ipv6.conf.default.accept_source_route = 0

## 3.3.2 Ensure ICMP redirects are not accepted
## 3.3.3 Ensure secure ICMP redirects are not accepted
## 3.3.5 Ensure broadcast ICMP requests are ignored 
## 3.3.6 Ensure bogus ICMP responses are ignored
/etc/sysctl.d/66_disable_icmp_problem_requests.conf:
  file.managed:
    - contents: |
          net.ipv4.conf.all.accept_redirects = 0
          net.ipv4.conf.default.accept_redirects = 0
          net.ipv6.conf.all.accept_redirects = 0
          net.ipv6.conf.default.accept_redirects = 0
          net.ipv4.conf.default.secure_redirects = 0
          net.ipv4.conf.all.secure_redirects = 0
          net.ipv4.icmp_ignore_bogus_error_responses = 1 

## 3.3.7 Ensure Reverse Path Filtering is enabled 
/etc/sysctl.d/67_enable_reverse_path_filtering.conf:
  file.managed:
    - contents: |
          net.ipv4.conf.all.rp_filter = 1
          net.ipv4.conf.default.rp_filter = 1

## 3.3.8 Ensure TCP SYN Cookies is enabled 
/etc/sysctl.d/68_ensure_tcp_syn_cookies.conf:
  file.managed:
    - contents: |
          net.ipv4.tcp_syncookies = 1

## 3.3.9 Ensure IPv6 router advertisements are not accepted
/etc/sysctl.d/69_dont_accept_IPV6_router_advertisements.conf:
  file.managed:
    - contents: |
          net.ipv6.conf.all.accept_ra = 0
          net.ipv6.conf.default.accept_ra = 0


### 3.4 Uncommon Network Protocols

## 3.4.1 Ensure DCCP is disabled 
/etc/modprobe.d/dccp.conf:
  file.managed:
    - contents: blacklist dccp


## 3.4.2 Ensure SCTP is disabled 
/etc/modprobe.d/sctp.conf:
  file.managed:
    - contents: blacklist sctp

## 3.4.3 Ensure RDS is disabled
/etc/modprobe.d/rds.conf:
  file.managed:
    - contents: blacklist rds

## 3.4.4 Ensure TIPC is disabled
/etc/modprobe.d/tipc.conf:
  file.managed:
    - contents: blacklist tipc

### 3.5 Firewall Configuration
{% if not pillar['shorewall']['install'] | default(False) %}
{% include "apps/simple_shorewall.sls" %}
{% include "apps/simple_shorewall6.sls" %}
{% endif %}


####
#### 4 Logging and Auditing
####

### 4.1 audit
{% include "basic_services/auditd.sls" %}

### LOG. Pillar will determine whether one of journald/rsyslog/syslog-ng will be used
### 4.2.1 journald
### 4.2.2 rsyslog/syslog-ng
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
    - mode: 0640
    - contents: |
          root

## 5.1.9 Ensure at is restricted to authorized users
/etc/at.deny: file.absent
/etc/at.allow:
  file.managed:
    - user: root
    - group: root
    - mode: 0640
    - contents: |
          root

### 5.2 Configure SSH Server
{% include "environment/sshd.sls" %}

### 5.3 Configure privilege escalation (SUDO/PKEXEC)
{% include "environment/users/sudo_manage.sls" %}

### 5.4 Configure PAM
{% include "cis-benchmark/pam/ubuntu.sls" %}

### 5.5 User Accounts and Environment
{% include "environment/users/cis_enforce.sls" %}

### CIS EXTRA. ajusta conta root
{% include "environment/users/root_manage.sls" %}

