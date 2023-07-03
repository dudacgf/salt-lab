#!jinja|yaml

{% if not grains['flag_zabbix_repo_installed'] | default(False) %}

{% if pillar['proxy'] != 'none' %}
{% set proxy = 'https_proxy=' + pillar['proxy'] %}
{% else %}
{% set proxy = '' %}
{% endif %}

{% if grains['os'] == 'Debian' %}

download repo deb:
  cmd.run: 
    - name: {{ proxy }} wget https://repo.zabbix.com/zabbix/6.0/debian/pool/main/z/zabbix-release/zabbix-release_6.0-4+debian{{ grains['osmajorrelease'] }}_all.deb -O /tmp/zabbix-release.deb

zabbix repo:
  cmd.run:
    - name: dpkg -i /tmp/zabbix-release.deb
    - require:
      - cmd: download repo deb
{% elif grains['os'] == 'Ubuntu' %}

download repo deb:
  cmd.run:
    - name:  {{ proxy }} wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu{{ grains['osrelease'] }}_all.deb -O /tmp/zabbix-release.deb 

zabbix repo:
  cmd.run:
    - name: dpkg -i /tmp/zabbix-release.deb
    - require:
      - cmd: download repo deb

{% elif grains['os_family'] == 'RedHat' %}
zabbix repo:
  cmd.run:
    - name:  {{ proxy }} rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/{{ grains['osmajorrelease'] }}/x86_64/zabbix-release-6.0-4.el{{ grains['osmajorrelease'] }}.noarch.rpm

exclude zabbix from epel:
  file.line:
    - name: /etc/yum.repos.d/epel.repo
    - mode: insert
    - after: '\[epel\]'
    - content: 'excludepkgs=zabbix*'

{% elif grains['os_family'] == 'Windows' %}
zabbix repo:
  test.nop:
    - name: '** win repo used'
{% else %}

'** OS Not Supported **':
  test.fail_without_changes:
    - failhard: True
{% endif %} # if grains['os']

flag_zabbix_repo_installed:
  grains.present:
    - value: True
    - require: 
      - zabbix repo

{% else %}

zabbix repo:
  test.nop:
    - name: '-- zabbix repo already installed'
{% endif %} # grains['flag_
