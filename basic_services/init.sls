#
## installs and setups basic services for linux (syslog, snmp, postfix etc)
{%- set bservices = pillar.get('basic_services', []) %}
{%- if bservices %}
include:
{%- for bservice in bservices %}
  - basic_services.{{ bservice }}
{%- endfor %}

{%- else %}
'-- no basic service to be installed.':
  test.nop
{%- endif %}
