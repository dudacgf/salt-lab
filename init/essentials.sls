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

{% if grains['os_family'] != 'Suse' %}
# 
## basic packages
minimal:
  pkg.installed:
    - pkgs:
      - {{ pillar['pkg_data']['python3']['python3-dns'] }}
      - python3-pycurl
      - python3-tornado
      - python3-pip
      - python3-devel
    - refresh: True
    - allow_updates: True
{% endif %}

prepara-pip:
  pkg.installed:
    - pkgs: [ {{ pillar['pkg_data']['salt-pycurl-requirements'] }} ]
    - refresh: True

minimal salt-minion:
  cmd.run:
    - name: '{{ pillar['pkg_data']['salt-pip'] }} -q install keystore pyjks m2crypto nmcli'

{% if not pillar['keep_gcc'] | default(False) %}
prepara-pip_remove:
  pkg.removed:
    - pkgs: [ {{ pillar['pkg_data']['salt-pycurl-requirements'] }} ]

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

