#
# use map value 'tdns_zones' dict values to create tdns.zone_managed states
#

{% from "utils/macros.sls" import dict_to_list %}

# read the map, filter by minion id, check if tdns_zones is defined
{% import_yaml 'maps/apps/tdns.yaml' as tdns %}
{% set tdns = salt.grains.filter_by(tdns, grain='id') %}

{% if 'tdns_zones' in tdns %}
{% for z in tdns.tdns_zones %}
{% set zone = tdns.tdns_zones[z] %}
"{{ z }}":
    tdns.zone_managed: {{ dict_to_list(zone) | trim("\n") }}
{% endfor %}

{% else %}
'-- no TDNS zones defined': test.nop

{% endif %}
