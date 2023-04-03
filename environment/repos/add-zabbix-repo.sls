#
# Adiciona o repositório do graylog
zabbix_repo:
  pkgrepo.managed:
    - name: deb https://repo.zabbix.com/zabbix/5.4/ubuntu focal main
    - humanname: Zabbix repo
    - dist: stable
    - file: /etc/apt/sources.list.d/zabbix.list
    - key_url: salt://files/env/GPG-KEY-zabbix

