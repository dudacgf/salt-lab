#
## configure.sls - sets configuration for a zabbix-proxy installation
#

/etc/zabbix/zabbix_proxy.conf:
  file.managed:
    - source: salt://files/services/zabbix/zabbix_proxy.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600

zabbix-proxy.service:
  service.running:
    - enabled: True
    - restart: True
    - watch:
      - file: /etc/zabbix/zabbix_proxy.conf
