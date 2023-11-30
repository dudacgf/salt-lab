#
# use map value 'tdns_dhcpscopes' dict values to create a tdns.dhcpscope_managed state
#

# read the map, filter by minion id, check if tdns_settings is defined
{% import_yaml 'maps/apps/tdns.yaml' as tdns %}
{% set tdns = salt.grains.filter_by(tdns, grain='id') %}

{% if 'tdns_dhcpscopes' in tdns %}
{% for d in tdns.tdns_dhcpscopes %}
{% set dhcpscope = tdns.tdns_dhcpscopes[d] %}
{{ dhcpscope.name }}:
    tdns.dhcpscope_managed: {{ dhcpscope }}
{% endfor %}

{% else %}
'-- no TDNS dhcp scopes defined': test.nop

{% endif %}
