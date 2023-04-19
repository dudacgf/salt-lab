#
# hosts_sample.sls - modelo para pillar relativo a hosts
#

# timezone do servidor
timezone: America/Sao_Paulo

# endereçamento IP
dhcp: True
#ip4_address: 192.168.0.30
#ip4_netmask: 255.255.255.0
#ip4_gateway: 192.168.0.254
#ip4_dns: [ '192.168.0.1', '192.168.0.2' ]

# se os_family for RedHat, define modo selinux (enforcing/permissive)
selinux_mode: permissive

# determina se vai obter certificados para esse servidor via certbot letsencrypt
certbot: False

# determina se vai registrar esse servidor no dns
register_dns: False

# servidor rede interna ou aberto para internet (internal/external)
location: internal

# se não for usar o domain default
internal_domain: a_domain.tld
external_domain: another_domain.tld

# postfix: determina se postfix vai enviar emails autenticados
postfix:
  auth: False
  relay: server_relay.a_domain.tld[:port] # :port é opcional. remova os colchetes
  user: username
  password: 'a very long and difficult to break password'

# determina se vai ou não gerenciar usuários nesse servidor
manage_users: True

# se precisar criar ou remover algum usuário além dos que estão em pillar/users.sls:
users_to_create:
  usuarioadicional:
    password: '$y$j9T$gBr53uVALsDglwMJoI14C/$T/IZa6QMUPdIYEhPvuiHgKqFb6f1S3zx7KbTgkGcu.C'
    homefiles:
      - .bashrc: salt://files/env/bashrc.jinja
    ssh_authorized_key: 'salt://files/pki/authorized_keys_usuario_adicional'

users_to_remove:
  administrator: True
  smtenorio: True

# extra aliases and functions to be inserted in ~user/.bashrc_aliases
aliases: [
  "vmprep='sudo virt-sysprep --operations bash-history,backup-files,dhcp-client-state,machine-id,-ssh-hostkey'",
  "clssh='for i in `seq 2 200` ; do ssh-keygen -f /home/${USER}/.ssh/known_hosts -R 10.1.115.${i} 2> /dev/null ; done'",
]

functions: [
  "vmip () { virsh guestinfo --domain ${1} | grep if.[0-9].addr.[0-9].addr | sed -- 's/.*: //' ; }",
  "port () { if [ -z ${1} ] ; then return ; else grep ${1} /etc/services ; fi ; }",
]

# roles em que esse minion vai atuar
roles: [ 'lamp' ]

# serviços executados no minion
services: ['apache', 'mariadb', 'php']

# determina se apache vai utilizar ssl
apache_ssl: True

# senha root do servidor mariadb
mariadb_root_pw: 'a hard password here'

# apps rodando no servidor
apps: [ 'wordpress', 'nextcloud-server' ]

# se vai instalar nrpe para o nagios ou não
nrpe: False

# wordpress 
wordpress:
  wp_site1:
    db_name: 'wp_db1'
    db_user: 'wp_user1'
    db_password: 'a very hard wp_passwd'
    db_host: 'localhost'
    site_source: salt://files/wordpress/wp_site1.tar.gz
    site_sql: salt://files/wordpress/wp_site1.sql

# Technitium dns settings
technitium_dns:
  admin_pw: 'a very hard password here, tks'
  zones:
    icatu_rede:
      name: localdomain.net
      type: forwarder
      dns: 192.168.0.1
    shiresco:
      zoneType: secondary
      zoneName: mainzone.tld
      tsigKeyName: xfr-over-tcp.key
      dns: 192.168.0.1
  block_lists: [
    https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts,
    https://s3.amazonaws.com/lists.disconnect.me/simple_tracking.txt,
    https://s3.amazonaws.com/lists.disconnect.me/simple_ad.txt,
    https://dbl.oisd.nl/ ]
  tsigs:
    tsig1:
      keyName: xfr-over-tcp.key
      sharedSecret: a very long shared secret
      algorithmName: hmac-sha256
    tsig2:
      keyName: ddns
      shareSecret: another very long shared secret
      algorithmName: hmac-sha256

# rede. 
# [Para o caso de redefinirem-se as interfaces de rede de um mínion]
interfaces:
  virbr1:
    itype: bridge
    zone: pub
  DMZ:
    hwaddr: '52:54:00:00:f0:02'
    itype: network
    dhcp: False
    ip4_address: 192.168.0.254
    ip4_netmask: 255.255.255.0
    zone: dmz

# shorewall
shorewall:
  install: True
  ip_forward: True
  startup_enabled: False
  snat: 
    enp1s0:
      - '192.168.0.0/24'
  zones: [ 'mgt', 'dmz', 'pub' ]
  interfaces:
    - zone: pub
      options: dhcp
    - zone: dmz
      hwaddr: '52:54:00:00:f0:02'
      options: dhcp
  hosts:
    # mgt zone: bastion server, salt server etc
    - zone: mgt
      ipaddrs: 'salt-master-ip,bastion-server-ip'
      options: dhcp
  policy:
    - action: ACCEPT
      source: fw
      dest: all
    - action: REJECT
      source: mgt
      dest: all
    - action: REJECT
      source: dmz
      dest: all
    - action: DROP
      source: pub
      dest: all
  rules:
    - protocol: tcp
      service: ssh
      source: [ 'mgt' ]
      dest: all
    - protocol: tcp
      service: http,https
      source: [ 'mgt' ]
      dest: dmz
    - protocol: tcp
      service: '4505,4506'
      source: [ 'all' ]
      dest: mgt:[salt-master-ip]
    - protocol: icmp
      service: echo-request
      source: [ 'all' ] 
      dest: all
    - protocol: udp
      service: domain
      source: [ 'all' ]
      dest: 'pub:dns-servers-ip-comma-separated'
    - protocol: udp
      service: syslog
      source: [ 'all' ]
      dest: 'pub:syslog-server-ip'
    - protocol: tcp
      service: 'http,https'
      source: [ 'dmz' ]
      dest: 'pub'

# 
dhcp-server:
  ranges:
    - subnet: 192.168.0.0
      mask: 255.255.255.0
      start: 192.168.0.10
      end: 192.168.0.99
      gateway: 192.168.0.254
      dns: [ '192.168.1.1', '192.168.1.2' ]

nextcloud:
  db_name: 'nextcloud'
  db_user: 'nextcloud'
  db_password: 'a very long and hard to break password'
  db_host: 'localhost'
  admin_user: 'admin_nextcloud'
  admin_password: 'another long password'
  ldap_config:
    s01:
      hasMemberOfFilterSupport: '1'
      ldapAgentName: 'wpress.ldap@a_domain.tld'
      ldapAgentPassword: 'hard to break agent password'
      ldapBackupHost: 'ad02.icatu.rede'
      ldapBackupPort: '389'
      ldapBase: 'OU=USERS,DC=a_domain,DC=tld'
      ldapBaseGroups: 'OU=GROUPS,DC=a_domain,DC=tld'
      ldapBaseUsers: 'OU=USERS,DC=a_domain,DC=tld'
      ldapCacheTTL: '600'
      ldapEmailAttribute: 'mail'
      ldapExperiencedAdmin: '0'
      ldapGidNumber: 'gidNumber'
      ldapGroupDisplayName: 'cn'
      ldapGroupFilter: '(&(|(objectclass=group))(|(cn=#Telecom)))'
      ldapGroupFilterGroups: '#Telecom'
      ldapGroupFilterMode: '0'
      ldapGroupFilterObjectclass: 'group'
      ldapGroupMemberAssocAttr: 'member'
      ldapHost: 'ad01.icatu.rede'
      ldapIgnoreNamingRules: ''
      ldapLoginFilter: '(&(&(|(objectclass=user)))(|(samaccountname=%uid)(|(mailPrimaryAddress=%uid)(mail=%uid))))'
      ldapLoginFilterEmail: '1'
      ldapLoginFilterMode: '0'
      ldapLoginFilterUsername: '1'
      ldapPort: '389'
      ldapQuotaAttribute: ''
      ldapQuotaDefault: ''
      ldapTLS: '0'
      ldapUserDisplayName: 'cn'
      ldapUserFilter: '(&(|(objectclass=user)))'
      ldapUserFilterObjectclass: 'user'
      useMemberOfToDetectMembership: '1'
      ldapConfigurationActive: '1'

