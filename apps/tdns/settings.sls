#
# use map value 'tdns_settings' dict values to create a tdns.server_configured state
#

# read the map, filter by minion id, check if tdns_settings is defined
{% import_yaml 'maps/tdns/tdns.yaml' as tdns %}
{% set tdns = salt.grains.filter_by(tdns, grain='id') %}

{% if 'tdns_settings' in tdns %}
server_settings:
    tdns.server_configured: {{ tdns.tdns_settings }}

{% else %}
'-- no TDNS server settings found': test.nop

{% endif %}
