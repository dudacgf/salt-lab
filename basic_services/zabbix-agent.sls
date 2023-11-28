#
## zabbix-agent2 - installs zabbix agent2 via zabbix official repos
#

{% if pillar['zabbix_install'] | default(False) %}
# remove old zabbix agent versions (maybe epel repo originated)
zabbix-agent:
  pkg.removed:
    - pkgs: [ zabbix-agent, zabbix6.0-agent ]

{% include 'environment/zabbix-repo.sls' ignore missing %}

{{ pillar['zabbix']['name'] }}:
  pkg.installed:
    - require:
      - zabbix repo

{{ pillar['zabbix']['conffile'] }}:
  file.managed:
    - source: salt://files/services/zabbix/zabbix_agent2.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

{{ pillar['zabbix']['name'] }}.service:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: {{ pillar['zabbix']['conffile'] }}

{% else %}
'-- zabbix agent will not be installed.':
  test.nop
{% endif %}

