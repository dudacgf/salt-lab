#
# use map 'tdns_zonerecords' dict values to create tdns.zone_managed states
#

# read the map, filter by minion id, check if tdns_zones is defined
{% import_yaml 'maps/apps/tdns.yaml' as tdns %}
{% set tdns = salt.grains.filter_by(tdns, grain='id',default='default') %}

{% if 'tdns_zonerecords' in tdns %}
{% for z in tdns.tdns_zonerecords %}
"{{ z.domain }}": 
  tdns.zonerecord_present: {{ z }}
{% endfor %}

{% else %}
'-- no TDNS zone records defined': test.nop

{% endif %}
