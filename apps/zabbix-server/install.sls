#
## install.sls - installs repos and zabbix packages
#
{% if grains['os_family'] == 'Debian' %}
zabbix_repo:
  pkgrepo.managed:
    - name: 'deb https://repo.zabbix.com/zabbix/6.4/ubuntu jammy main'
    - file: /etc/apt/sources.list.d/zabbix.list
    - key_url: salt://files/env/GPG-KEY-zabbix
{% elif grains['os_family'] == 'RedHat' %}
# força aceitação de sha-1 signed keys
permit sha1 keys:
  cmd.run:
    - name: update-crypto-policies --set LEGACY

zabbix_repo:
  pkgrepo.managed:
    - name: zabbix
    - humanname: Zabbix Official Repository - $basearch
    - baseurl: https://repo.zabbix.com/zabbix/6.4/rhel/9/$basearch/
    - enabled: True
    - gpgcheck: 1
    - gpgkey: http://repo.zabbix.com/RPM-GPG-KEY-ZABBIX-08EFA7DD

exclude zabbix from epel:
  file.line:
    - name: /etc/yum.repos.d/epel.repo
    - mode: insert
    - after: '\[epel\]'
    - content: 'excludepkgs=zabbix*'

{% else %}
'** OS Not Supported **':
  test.fail_without_changes:
    - failhard: True
{% endif %}

install zabbix server:
  pkg.installed:
    - pkgs: [zabbix-server-mysql, zabbix-web-mysql, zabbix-apache-conf, zabbix-sql-scripts, zabbix-selinux-policy, zabbix-agent]

