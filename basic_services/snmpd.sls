{%- if not pkg_data is defined %}
{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
{%- endif %}
#
## snmpd.sls - instala e configura o serviço snmpd para monitoramento via nagios e/ou cacti
# 
{{ pkg_data.snmpd.name }}:
  pkg.installed
  
#
# arquivo de configuração do serviço
/etc/snmp/snmpd.conf:
  file.managed:
    - source: salt://files/services/snmpd.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - backup: minion

# 
# ajusta o serviço snmpd
snmpd.service: 
  service.running:
    - enable: true
    - reload: true
    - watch:
      - file: /etc/snmp/snmpd.conf

