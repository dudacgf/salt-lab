{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
#
## snmpd.sls - instala e configura o serviço snmpd para monitoramento via nagios e/ou cacti
# 

{%- if salt.service.status('rsyslog') %}
rsyslog:
  pkg.removed
{%- endif %}

install-syslog-ng:
  pkg.installed:
    - pkgs: [ {{ pkg_data.syslog-ng.name }}, {{ pkg_data.syslog-ng.mod_http }} ]
  
#
# arquivo de configuração do serviço
/etc/syslog-ng/syslog-ng.conf:
  file.managed:
    - source: salt://files/services/syslog-ng/syslog-ng.{{ grains['os_family'] | lower }}.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - backup: minion

#
# configuração para enviar auditd log para graylog
{% if pillar['audit2graylog'] | default(False) %}
/etc/syslog-ng/conf.d/auditd-graylog-parser.conf:
  file.managed:
    - source: salt://files/services/syslog-ng/auditd-graylog-parser.conf
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - backup: minion

#
## sistemas com SELINUX ligado precisam permitir que syslog-ng acesse
## o diretório /var/log/audit
#
{% if grains['os_family'] == 'RedHat' and not grains['flag_semode_syslog_run'] | default(False) %}
# copia as diretivas captadas através de ausearch | audit2allow
/tmp/syslog-ng-selinux.pp:
  file.managed:
    - source: salt:///files/selinux/syslog-ng-selinux.pp
    - user: root
    - group: root
    - mode: 644

# executa as diretivas
semodule -X 300 -i /tmp/syslog-ng-selinux.pp:
  cmd.run:
    - require:
      - file: /tmp/syslog-ng-selinux.pp

# marca como já executado para não repetir no próximo highstate
flag_semode_syslog_run:
  grains.present:
    - value: True
{% endif %}
{% endif %} # audit2graylog

# 
# ajusta o serviço syslog-ng
syslog-ng.service: 
  service.running:
    - enable: true
    - reload: true
    - watch:
      {%- if pillar['audit2graylog'] | default(False) %}
      - file: /etc/syslog-ng/conf.d/auditd-graylog-parser.conf
      {%- endif %}
      - file: /etc/syslog-ng/syslog-ng.conf

