{%- if pillar['duo'] | default(False) and pillar['duo']['install'] | default(False) %}
include:
  - .duo_install
  - .duo_system
  - .duo_ssh
{%- else -%}
'-- Duo will not be installed.':
  test.nop
{%- endif %}
