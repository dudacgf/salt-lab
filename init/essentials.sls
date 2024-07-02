{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
#
## essentials.sls - packages and basic setup needed for everything and some
# 

#
## clean packager cache before anything
{{ pkg_data.packager }} clean all:
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
{% if grains['os_family'] != 'Suse' %}
minimal:
  pkg.installed:
    - pkgs:
      - {{ pkg_data.python3.version }}-pycurl
      - {{ pkg_data.python3.version }}-tornado
      - {{ pkg_data.python3.version }}-pip
      - {{ pkg_data.python3.version }}-{{ pkg_data.python3.devel }}
      - {{ pkg_data.python3.version }}-wheel
      - {{ pkg_data.python3.version }}-scp
      - {{ pkg_data.python3.version }}-{{ pkg_data.python3.dnspython }}
      - {{ pkg_data.python3.version }}-{{ pkg_data.python3.yaml }}
    - refresh: True
    - allow_updates: True
{% endif %}

prepara-pip:
  pkg.installed:
    - pkgs: [ {{ pkg_data.salt_pycurl_requirements }} ]
    - refresh: True

{% set proxy = '--proxy ' + pillar.proxy if pillar.proxy else '' %}
minimal salt-minion:
  cmd.run:
    - name: '{{ pkg_data.python3.pip_version }} {{ proxy }} -q install pip keystore pyjks m2crypto==0.38.0 nmcli scp dnspython pyyaml --upgrade'

{% if not pillar['keep_gcc'] | default(False) %}
prepara-pip_remove:
  pkg.removed:
    - pkgs: [ {{ pkg_data.salt_pycurl_requirements }} ]

{% endif %}

#
# x509 deprecation handling
/etc/salt/minion.d/x509.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 0644
    - contents: |
        # 
        # handling of x509 module deprecation
        features:
          x509_v2: true

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

'-- essentials run': test.nop
