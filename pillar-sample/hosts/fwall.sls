#
# fwall.sls - pillar file for a generic 3 interface firewall (DMZ, LOC, NET)
#

locale: 'pt_BR.UTF-8'
keymap: us-intl

services: [ 'dhcp-server', 'squid' ]

# IP Addressing of main network card (from libvirt profile image)
dhcp: False
ip4_address: 10.1.115.200
ip4_netmask: 255.255.255.0
ip4_gateway: 10.1.115.254
ip4_dns: [ '10.1.16.1', '10.1.16.2' ]

# Will not use certbot to create certificates 
# (they should be stored at files/pki/CA. see samples at doc/pki)
certbot: False

# Will not register this server at a dns service
# (currently only godaddy api is available)
register_dns: False

# Will use internal domain name
location: internal

# Will not use default internal domain name
# (default defined at pillar/defaults.sls)
internal_domain: icatu.rede

# postfix: will install, will not authenticate 
# (office365 relays only to same external domain accounts)
postfix:
  install: True
  auth: False
  relay: icatu-com-br.mail.protection.outlook.com

# 
apache_ssl: True

# 
manage_users: True

# 
selinux_mode: permissive

# 
nrpe: False

# 
proxy: http://10.1.115.1:3128

# squid install parameters
squid:
  transparent: False
  ssl_enable: False

# extra aliases 
aliases: [
  "tq='sudo tail -f /var/log/squid/access.log'",
  "tsc='sudo tail -f /var/log/squid/cache.log'",
]

# redefine network cards
redefine_interfaces: True
interfaces:
  virbr1:
    itype: 'bridge'
    hwaddr: '52:54:00:40:f0:00'
    dhcp: False
    ip4_address: 10.1.115.200
    ip4_netmask: 255.255.255.0
    ip4_gateway: 10.1.115.254
    ip4_dns: [ '10.1.16.1', '10.1.16.2' ]
  LOC:
    hwaddr: '52:54:00:40:f0:01'
    itype: 'network'
    dhcp: False
    ip4_address: 10.1.200.254
    ip4_netmask: 255.255.255.0
  DMZ:
    hwaddr: '52:54:00:40:f0:02'
    itype: 'network'
    dhcp: False
    ip4_address: 10.1.201.254
    ip4_netmask: 255.255.255.0
  MNT:
    hwaddr: '52:54:00:40:f0:03'
    itype: 'network'
    dhcp: False
    ip4_address: 10.1.202.254
    ip4_netmask: 255.255.255.0

# shorewall firewall configuration
shorewall:
  install: True
  ip_forward: Yes
  startup_enabled: Yes
  zones: [ 'mgt', 'loc', 'dmz', 'mnt', 'pub' ]
  interfaces:
    1:
      zone: pub
      options: dhcp
      hwaddr: '52:54:00:40:f0:00'
    2:
      zone: loc
      hwaddr: '52:54:00:40:f0:01'
      options: dhcp
    3:
      zone: dmz
      hwaddr: '52:54:00:40:f0:02'
      options: dhcp
    4:
      zone: mnt
      hwaddr: '52:54:00:40:f0:03'
      options: dhcp
  hosts:
    1:
      zone: mgt
      ipaddrs: '10.1.111.1,10.1.115.1'
      hwaddr: '52:54:00:40:f0:00'
      options: dhcp
  policy:
    - action: ACCEPT
      source: fw
      dest: all
    - action: REJECT
      source: mgt
      dest: all
    - action: REJECT
      source: loc
      dest: all
    - action: REJECT
      source: dmz
      dest: all
    - action: REJECT
      source: mnt
      dest: all
    - action: DROP
      source: pub
      dest: all
  snat: 
    - hwaddr: '52:54:00:40:f0:00'
      sources: ['10.1.200.0/24', '10.1.201.0/24', '10.1.202.0/24']
  rules:
    - protocol: tcp
      service: 3128
      action: ACCEPT
      source: [ 'mnt', 'loc', 'dmz' ]
      dest: fw
    - protocol: tcp
      service: ssh
      action: ACCEPT
      source: [ 'mgt' ]
      dest: all
    - protocol: tcp
      service: 9090-9199
      source: [ 'mnt:10.1.202.135' ]
      dest: all
    - protocol: tcp
      service: http,https
      action: ACCEPT
      source: [ 'all' ]
      dest: dmz
    - protocol: tcp
      service: http,https,9000
      action: ACCEPT
      source: [ 'loc' ]
      dest: mnt:labg.icatu.rede
    - protocol: tcp
      service: ssh
      action: ACCEPT
      source: [ 'mgt' ]
      dest: loc
    - protocol: tcp
      service: ssh
      action: ACCEPT
      source: [ 'mgt' ]
      dest: fw
    - protocol: tcp
      service: '4505,4506'
      action: ACCEPT
      source: [ 'all' ]
      dest: mgt:10.1.111.1
    - protocol: icmp
      service: echo-request
      action: ACCEPT
      source: [ 'all' ]
      dest: all
    - protocol: udp
      service: domain
      action: ACCEPT
      source: [ 'all' ]
      dest: 'pub:10.1.16.1,10.1.16.2,8.8.8.8'
    - protocol: tcp
      service: 4514
      action: ACCEPT
      source: [ 'all' ]
      dest: 'pub:10.1.16.240'
    - protocol: udp
      service: syslog
      action: ACCEPT
      source: [ 'all' ]
      dest: 'pub:10.1.16.235'
    - protocol: tcp
      service: 'http,https'
      action: ACCEPT
      source: [ 'loc', 'dmz' ]
      dest: 'pub'
    - protocol: tcp
      service: http,https
      action: REDIRECT
      source: [ 'loc' ]
      dest: '3128'
    - protocol: tcp
      service: 3128
      action: ACCEPT
      source: [ 'all' ]
      dest: 'mgt:10.1.115.1'

# dhcp server configuration
dhcp-server:
  ranges:
    - subnet: 10.1.200.0
      mask: 255.255.255.0
      start: 10.1.200.10
      end: 10.1.200.99
      gateway: 10.1.200.254
      dns: [ '10.1.16.1', '10.1.16.2' ]
    - subnet: 10.1.201.0
      mask: 255.255.255.0
      start: 10.1.201.10
      end: 10.1.201.99
      gateway: 10.1.201.254
      dns: [ '10.1.16.1', '10.1.16.2' ]
    - subnet: 10.1.202.0
      mask: 255.255.255.0
      start: 10.1.202.10
      end: 10.1.202.99
      gateway: 10.1.202.254
      dns: [ '10.1.16.1', '10.1.16.2' ]
