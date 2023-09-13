## waits for minion
{% macro wait_minion(mname, sleep_name='sleep') %}
{% for i in range(0,20) %}
{{ sleep_name }} sleep {{ pillar['sleep_a_while'] }} {{ i }}:
  module.run:
    - name: test.sleep
    - length: {{ pillar['sleep_a_while'] }}

{% set rc = salt['cmd.run']('salt ' + mname + ' test.ping --out yaml') | load_yaml %}
{% if rc[mname] %}
  {% break %}
{% endif %}

{% endfor %}

{% endmacro %}
