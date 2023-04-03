#
# Ajusta timezone 
{% set timezone = salt['cmd.run']('timedatectl show --property=Timezone --value') %}
{% set tz = salt['pillar.get']('timezone', 'UTC') %}

{%if timezone != tz %}
Ajusta_timezone:
  timezone.system:
    - name: {{ tz }}
{% endif %}

