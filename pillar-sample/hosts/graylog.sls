#
# graylog.sls - pillar file that defines a graylog siem server
#
roles: [ 'graylog' ]

nrpe: False

dhcp: True

register_dns: False
selinux_mode: enforcing

location: internal

proxy: http://10.1.115.1:3128

manage_users: True

graylog:
  ssl_enable: true
  listen_address: '0.0.0.0'
  root_pw_sha2: 'DY5gaW32uT'
  mongodb_user: graylogAdmin
  mongodb_pw: gRYuSr99634

elasticsearch:
  ssl_enable: True
  cluster_name: 'graylog'
  listen_address: 'labg.icatu.rede'
  auth: True
  passwords:
    apm_system: vga6n2NjprJVTTXTroT4
    kibana_system: uazEDndDP2tMFfHiRtNK
    kibana: uazEDndDP2tMFfHiRtNK
    logstash_system: kA9gkA4RmdtdDZcBCKV8
    beats_system: KDu6aED0oVidCNNsI3Wk
    remote_monitoring_user: zfbQGleuFbTVREVCPvrG
    elastic: aqA71o8hdN3AcUCKqD0p

kibana:
  ssl_enable: True

mongodb:
  ssl_enable: False
  auth: true
  admin_user: 'admin'
  admin_pw: 'bxubXkF3'

postfix:
  install: False

redefine_interfaces: True
interfaces:
  MNT:
    hwaddr: '52:10:01:20:22:40'
    dhcp: False
    itype: network
    ip4_address: 10.1.202.240
    ip4_netmask: 255.255.255.0
    ip4_gateway: 10.1.202.254
    ip4_dns: [ '10.1.16.1', '10.1.16.2' ]

audit2graylog: true
graylog_server: 10.1.202.240

aliases: [
  "tg='sudo tail -f /var/log/graylog-server/server.log'",
]

