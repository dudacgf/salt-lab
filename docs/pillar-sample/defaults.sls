timezone: America/Sao_Paulo
location: internal
keymap: br-abnt2
langpack: pt
locale: pt_BR.UTF8
manage_users: True
dhcp: True
certbot: False
apache:
  ssl_enable: False
register_dns: False
set_hostname: True
selinux_mode: enforcing
nrpe: false
postfix:
  install: False
  auth: True
org_ca:
  self_signed: True
  ca_file: salt://files/pki/CA_Icatu.pem
redefine_interfaces: False
sleep_a_while: 15
sleep_a_longer_while: 60
install_nonfree: False

