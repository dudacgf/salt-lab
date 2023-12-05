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
