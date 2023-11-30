{% if not pillar['tdns'] is defined %}

dismiss config:
  test.show_notification:
    - text: '-- no TDNS configuration found. exiting.'

{% else %}
#
# nova senha
{% if not grains['flag_technitium_admin_pw_set'] | default(False) %}
tdns.change_admin_password:
  module.run:
    - new_pw: {{ pillar['tdns']['admin_pw'] | default('admin') }}

flag_technitium_admin_pw_set:
  grains.present:
    - value: True
    - require:
      - tdns.change_admin_password

{% endif %}

#
# server settings
include:
  # server settings
  - apps.tdns.settings
  # dns authoritative zones
  - apps.tdns.zones
  # dhcp scopes definition
  - apps.tdns.dhcpscopes
  # zone resource records
  - apps.tdns.zonerecords

{%- endif %} # tdns is defined
