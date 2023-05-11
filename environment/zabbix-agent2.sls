#
## zabbix-agent2 - installs zabbix agent2 via zabbix official repos
#

# remove old zabbix agent versions (maybe epel repo originated)
zabbix-agent:
  pkg.removed:
    - pkgs: [ zabbix-agent, zabbix6.0-agent ]

{% include 'environment/zabbix-repo.sls' ignore missing %}

zabbix-agent2:
  pkg.installed:
    - require:
      - zabbix repo

/etc/zabbix/zabbix_agent2.conf:
  file.managed:
    - source: salt://files/services/zabbix/zabbix_agent2.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

zabbix-agent2.service:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/zabbix/zabbix_agent2.conf

