#
## installs and setups basic services for linux (syslog, snmp, postfix etc)

{% set bservices = pillar.get('basic_services', []) %}
{% if bservices %}
{% for bservice in bservices %}

{% include 'basic_services/' + bservice + '.sls' ignore missing %}
{% include 'basic_services/' + bservice + '/init.sls' ignore missing %}

{% endfor %}
{% else %}
'-- no basic service to be installed.':
  test.nop
{% endif %}
{#
include:
  - basic_services.syslog-ng
  - basic_services.fail2ban
  - basic_services.auditd
  - basic_services.aide
  - basic_services.chrony
  - basic_services.nrpe
  - basic_services.zabbix-agent
  - basic_services.snmpd
  - basic_services.postfix
#}
