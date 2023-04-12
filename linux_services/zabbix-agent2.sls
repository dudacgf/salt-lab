#
## zabbix-agent2 - installs zabbix agent2 via zabbix official repos
#

{% include 'enviroment/zabbix-repo.sls' %}

zabbix-agent2:
  pkg.installed:
    - require:
      - zabbix_repo



