{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
### 2.1 Special Purpose Services

## 2.1.1 Ensure autofs are not in use
## already done in 1_1_file_systems.sls
## autofs: pkg.purged

## 2.1.2 Ensure Avahi Server is not installed
{{ pkg_data.avahi.name }}: pkg.purged

## 2.1.3 Ensure DHCP Server is not installed 
{% if not 'dhcp-server' in pillar['services'] | default(False) %}
{{ pkg_data.dhcp_server.name }}: pkg.purged
{% endif %}

## 2.1.4 Ensure DNS Server is not installed 
{% if not 'bind9' in pillar['services'] | default(False) %}
{{ pkg_data.named.name }}: pkg.purged
{% endif %}

## 2.1.5 Ensure dnsmasq is not installed
dnsmasq: pkg.purged

## 2.1.6 Ensure FTP Server is not installed
vsftpd: pkg.purged

## 2.1.7 Ensure LDAP server is not installed 
{% if not 'ldap-server' in pillar['services'] | default(False) %}
ldapd: pkg.purged
{% endif %}

## 2.1.8 Ensure IMAP and POP3 server are not installed
purge imap pop3:
  pkg.purged:
    - pkgs: [{{ pkg_data.dovecot.name | join(', ') }} ]

## 2.1.9 Ensure NFS is not installed 
{{ pkg_data.nfs.name }}: pkg.purged

## 2.1.10 Ensure NIS Server is not installed
nis: pkg.purged

## 2.1.11 Ensure CUPS is not installed
cups: pkg.purged

## 2.1.12 Ensure rpcbind services are not in use
rpcbind: pkg.purged

## 2.1.13 Ensure rsync service is either not installed or masked
rsync.service:
  service.dead:
    - enable: False

## 2.1.14 Ensure Samba is not installed
{% if pillar['netshares'] | default('none') != 'none' %}
samba: pkg.purged
{% endif %}

## 2.1.15 Ensure SNMP Server is not installed 
{% if not 'snmpd' in pillar['basic_services'] | default(False) %}
{{ pkg_data.snmpd.name }}: pkg.purged
{% endif %}

## 2.1.16 Ensure tftp server services are not in use
{{ pkg_data.tftp.server }}: pkg.purged

## 2.1.17 Ensure HTTP Proxy Server is not installed 
{% if not 'squid' in pillar['services'] | default(False) %}
squid: pkg.purged
{% endif %}

## 2.1.18 Ensure HTTP server is not installed 
{% if not 'apache' in pillar['services'] | default(False) %}
{{ pkg_data.apache.name }}: pkg.purged
{% endif %}

## 2.1.19 Ensure xinetd services are not in use
xinetd: pkg.purged

## 2.1.20 Ensure X window server services are not in use
# already done at 1_8_gnome
{#% if 'apps' in pillar and 'gnome-desktop' not in pillar.apps %}
{{ pkg_data.gnome.xserver }}: pkg.purged
{% endif %#}

## 2.1.21 Ensure mail transfer agent is configured for local-only mode
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

