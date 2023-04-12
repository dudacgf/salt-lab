#
## zabbix-server - installs zabbix server via zabbix official repos
#

{% include 'enviroment/zabbix-repo.sls' %}

install zabbix server:
  pkg.installed:
    - pkgs: [zabbix-server-mysql, zabbix-web-mysql, zabbix-apache-conf, zabbix-sql-scripts, zabbix-selinux-policy, zabbix-agent]
    - require:
      - zabbix_repo

