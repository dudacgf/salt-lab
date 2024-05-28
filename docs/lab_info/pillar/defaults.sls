# location info
timezone: UTC
location: internal
keymap: us
langpack: us
locale: us_EN.UTF-8

# manage users via map/users?
manage_users: True

# register minion on dns
register_dns: False

# create letsencrypt certificate
certbot: False

# enforce cis recommendations
cis: enforced

# cis recomendations parameters
cis_parms: 
  user: root
  password: apassword
  grub_boot_password: # generated via command grub2-mkpasswd-pbkdf2

# dns hosters we know how to register
supported_dns_hosters: ['aws', 'godaddy', 'tdns', 'bind9']
# domains that can directly register a host
certbox_ok_domains: ['example.com']

# if will use certificates
apache:
  ssl_enable: True

# if will set the hostname
set_hostname: True

# for redhat and derivatives 
selinux_mode: enforcing

# we used nagios as monitoring tool, and are migrating to zabbix
nrpe_install: false
zabbix_agent_install: False

# postfix info. see linux_services.postfix for other variables
postfix:
  install: False
  auth: False

# if the organization uses self_signed certificates (e.g., AD)
org_ca:
  self_signed: True
  ca_file: salt://files/pki/CA.pem

# if will send audit logs to graylog and if will use tls
audit2graylog: False
audit2graylog_tls: False

install_nonfree: False

duo:
  install: False
  login: True
  ssh: True
  sudo: True

proxy: False
redefine_proxy: 'none'

shorewall:
  install: False

simple_shorewall:
  rules_in:
    - tcp
      ssh
  rules_out:
    - tcp
      http,https
    - tcp
      4505,4506

basic_services: []
drivers: []
services: []
roles: []
apps: []


