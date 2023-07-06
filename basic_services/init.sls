#
## ajusta os serviços básicos de um servidor Linux

include:
  - basic_services.syslog-ng
  - basic_services.fail2ban
  - basic_services.auditd
#  - basic_services.aide
  - basic_services.chrony
  - basic_services.nrpe
  - basic_services.snmpd
  {%- if pillar['postfix']['install'] %}
  - basic_services.postfix
  {%- endif %}

