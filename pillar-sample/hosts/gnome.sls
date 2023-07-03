#
## gnome.sls - pillar file to define a gnome workstation
#
certbot: False
dhcp: True

apps: ['gnome-desktop', 'firefox-esr', 'brave-browser']

postfix:
  install: false

proxy: "http://10.1.115.1:3128"

redefine_interfaces: True
interfaces:
  LOC:
    hwaddr: '52:54:00:50:f0:01'
    itype: network
    dhcp: True

