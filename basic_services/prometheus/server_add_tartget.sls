#
## add_target.sls - adiciona um target ao servidor prometheus.
#

# lista de exporters conhecidos e suas respectivas portas
{% set ports = {"node": 9100, "apache": 9117, "snmp": 9116, "mysqld": 9104, "postfix": 9154} %}

# dados passados no event.send quando os exporters fooram instalados
{% set hostname = pillar['data']['hostname'] }}
{% set ipv4 = pillar['data']['ipv4'] | first() }}

{% set targetlist = [] %}
{%- for exporter in pillar['data']['prometheus_exporters'] %}
   {%- set port = ports[exporter] %}
   {%- do targetlist.append('"{{ ipv4 }}:{{ port }})"') %}
{%- endfor %}

# o input file tem o formato: 
cria target file:
  file.managed:
    - name: /etc/prometheus/targets.d/{{ hostname }}.json
    - user: prometheus
    - group: prometheus
    - contents:
      - '['
      - ' {'
      - '   "targets": [ {{ targetlist | join(',') }} ],'
      - '   "labels": {'
      - '     "env": "prod",'
      - '     "job": "node"'
      - '   }'
      - ' }'
      - ']'

