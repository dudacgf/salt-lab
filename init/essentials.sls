#
## essentials.sls - packages and basic setup needed for everything and some
# 

#
## clean packager cache before anything
{{ pillar['pkg_data']['packager'] }} clean all:
  cmd.run


## runs updates before anything else
upgrades:
  pkg.uptodate:
    - refresh: True

{%- if grains['os_family'] == 'Debian' %}
apt-get dist-upgrade -y: cmd.run
{%- endif %}

# 
## basic packages
minimal:
  pkg.installed:
    - pkgs:
      - python3-dns
      - python3-pycurl
      - python3-tornado
      - python3-pip
      - uuid
    - refresh: True
    - allow_updates: True

prepara-pip:
  pkg.installed:
    - pkgs: [ {{ pillar['pkg_data']['salt-pycurl-requirements'] }} ]
    - refresh: True

minimal salt-minion:
  cmd.run:
    - name: 'salt-pip -q install pycurl tornado keystore pyjks m2crypto'

{% if not pillar['keep_gcc'] | default(False) %}
prepara-pip_remove:
  pkg.removed:
    - pkgs: [ {{ pillar['pkg_data']['salt-pycurl-requirements'] }} ]

{% endif %}

#
## is this a vmware vm?
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
    #- install_options:
      #- --break-system-packages
    - args:
      - --use-pep517
{% endif %}

# 
## sync modules, functions etc
sync all:
  saltutil.sync_all

#
## restart minion 
restart salt minion:
  cmd.run:
    - name: /bin/bash -c 'sleep 5; shutdown -r now'
    - bg: True

