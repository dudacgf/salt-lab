/etc/zabbix/zabbix_server.conf:
  file.managed:
    - source: salt://files/services/zabbix_server.conf.jinja
    - template: jinja
    - user: root
    - group: zabbix
    - mode: 600

zabbix-server.service:
  service.running:
    - enabled: True
    - restart: True
    - watch:
      - file: /etc/zabbix/zabbix_server.conf
