#
## essentials.sls - packages and basic setup needed for everything and some
# 

#
## basic packages
# 
minimal:
  pkg.installed:
    - pkgs:
      - python3-dns
      - python3-pycurl
      - python3-tornado
      - python3-netifaces
      - python3-pip

#
## is this an vmware vm?
#
{% if grains['manufacturer'] == 'VMware, Inc.' %}
open-vm-tools:
  pkg.installed

vmtoolsd.service:
  service.running:
    - enable: True

{% endif %}

# 
## this one has no package
install python3-nmcli:
  pip.installed:
    - name: nmcli >= 1.1.2

# 
## sync modules, functions etc
sync all:
  saltutil.sync_all

#
## restart minion 
restart salt minion:
  cmd.run:
    - name: 'salt-call --local service.restart salt-minion'
    - bg: True
    - require:
      - saltutil: sync all

