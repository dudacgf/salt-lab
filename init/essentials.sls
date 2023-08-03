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

prepara-pip:
  pkg.installed:
    - pkgs: [ {{ pillar['pkg_data']['salt-pycurl-requirements'] }} ]

minimal salt-minion:
  cmd.run:
    - name: 'salt-pip install netifaces pycurl tornado'

{% if not pillar['keep_gcc'] | default(False) %}
prepara-pip_remove:
  pkg.removed:
    - pkgs: [ {{ pillar['pkg_data']['salt-pycurl-requirements'] }} ]

{% endif %}

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
    - name: nmcli 
{%- if grains['os'] == 'Debian' and grains['osmajorrelease'] > 11 %}
    - install_options:
      - --break-system-packages
{% endif %}

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

