#!jinja|yaml

{% if 'proxy' in pillar and pillar.proxy | default(False) %}
{% set proxy = 'https_proxy=' + pillar['proxy'] %}
{% else %}
{% set proxy = '' %}
{% endif %}

{% if grains['os'] in ['Debian', 'Mint'] %}
{% set osmr = '12' if grains['os'] == 'Mint' else grains['osmajorrelease'] %}
download repo deb:
  cmd.run: 
    - name: {{ proxy }} wget https://repo.zabbix.com/zabbix/7.2/release/debian/pool/main/z/zabbix-release/zabbix-release_latest%2Bdebian{{ osmr }}_all.deb -O /tmp/zabbix-release.deb

zabbix repo:
  cmd.run:
    - name: dpkg --force-confdef -i /tmp/zabbix-release.deb
    - require:
      - cmd: download repo deb
{% elif grains['os'] == 'Ubuntu' %}

download repo deb:
  cmd.run:
    - name:  {{ proxy }} wget https://repo.zabbix.com/zabbix/7.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest%2Bubuntu22.04_all.deb -O /tmp/zabbix-release.deb

zabbix repo:
  cmd.run:
    - name: dpkg --force-confdef -i /tmp/zabbix-release.deb
    - require:
      - cmd: download repo deb

{% elif grains['os_family'] == 'RedHat' %}
zabbix repo:
  cmd.run:
    - name:  {{ proxy }} rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rocky/{{ grains.osmajorrelease }}/x86_64/zabbix-release-latest.el9.noarch.rpm
    - unless: grep -qs 'baseurl=https://repo.zabbix.com/zabbix/6.5/rhel/' /etc/yum.repos.d/zabbix.repo 

exclude zabbix from epel:
  file.line:
    - name: /etc/yum.repos.d/epel.repo
    - mode: insert
    - after: '\[epel\]'
    - content: 'excludepkgs=zabbix*'

{% elif grains['os_family'] == 'Windows' %}
zabbix repo:
  test.nop:
    - name: '-- win repo used'
{% else %}

'-- OS Not Supported':
  test.fail_without_changes:
    - failhard: True
{% endif %} # if grains['os']
