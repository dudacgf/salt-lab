{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
#
## zabbix-agent2 - installs zabbix agent2 via zabbix official repos
#

{% if pillar['zabbix_agent_install'] | default(False) %}
# remove old zabbix agent versions (maybe epel repo originated)
zabbix-agent:
  pkg.removed:
    - onlyif: salt-call -l quiet --local service.available zabbix-agent

{% include 'basic_services/zabbix-repo.sls' ignore missing %}

{{ pkg_data.zabbix.agent_name }}:
  pkg.installed:
    - require:
      - zabbix repo

{{ pkg_data.zabbix.conffile }}:
  file.managed:
    - source: salt://files/services/zabbix/zabbix_agent2.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

/etc/zabbix/zabbix_agent2.d/plugins.d/90-updates.conf:
  file.managed:
    - source: salt://files/services/zabbix/90-updates.conf.jinja
    - mode: 0644
    - template: jinja
  
{% if grains['os_family'] == 'RedHat' %}
cron updates:
  cron.present:
    - identifier: linux.updates
    - name: LANG=C dnf -q list --updates 2> /dev/null | grep -vcE '^Available|^Last' > /var/run/zabbix/updates.txt
    - minute: 0
    - hour: '*/6'

LANG=C dnf -q list --updates 2> /dev/null | grep -vcE '^Available|^Last' > /var/run/zabbix/updates.txt || true : cmd.run

cron sec_updates:
  cron.present:
    - identifier: linux.sec_updates
    - name: LANG=C dnf -q list --updates --security 2> /dev/null | grep -vcE '^Available|^Last' > /var/run/zabbix/sec_updates.txt
    - minute: 0
    - hour: '*/6'

LANG=C dnf -q list --updates --security 2> /dev/null | grep -vcE '^Available|^Last' > /var/run/zabbix/sec_updates.txt || true : cmd.run

{% elif grains['os_family'] == 'Debian' %}
cron updates:
  cron.present:
    - identifier: linux.updates
    - name: LANG=C apt-get -qq upgrade -s | grep -c ^Inst > /var/run/zabbix/updates.txt
    - minute: 0
    - hour: '*/6'

LANG=C apt-get -qq upgrade -s | grep -c ^Inst > /var/run/zabbix/updates.txt ||  true: cmd.run

cron sec_updates:
  cron.present:
    - identifier: linux.sec_updates
    - name: LANG=C apt-get -qq upgrade -s | grep ^Inst | grep -c security > /var/run/zabbix/sec_updates.txt
    - minute: 0
    - hour: '*/6'

LANG=C apt-get -qq upgrade -s | grep ^Inst | grep -c security > /var/run/zabbix/sec_updates.txt || true: cmd.run
{% endif %}

{{ pkg_data.zabbix.agent_name }}.service:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: {{ pkg_data.zabbix.conffile }}
      - file: /etc/zabbix/zabbix_agent2.d/plugins.d/90-updates.conf
      - cron: cron updates
      - cron: cron sec_updates

{% else %}
'-- zabbix agent will not be installed.':
  test.nop
{% endif %}

