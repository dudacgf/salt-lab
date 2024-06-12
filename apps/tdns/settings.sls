#
# use map value 'tdns_settings' dict values to create a tdns.server_configured state
#

{% from "utils/macros.sls" import dict_to_list %}

# read the map, filter by minion id, check if tdns_settings is defined
{% import_yaml 'maps/apps/tdns.yaml' as tdns %}
{% set tdns = salt.grains.filter_by(tdns, grain='id') %}

{% if 'tdns_settings' in tdns %}
server_settings:
  tdns.server_configured: {{ dict_to_list(tdns.tdns_settings) | trim("\n") }}

{% else %}
'-- no TDNS server settings found': test.nop

{% endif %}
