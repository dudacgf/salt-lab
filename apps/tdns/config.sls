{% if not pillar['tdns'] is defined %}

dismiss config:
  test.show_notification:
    - text: '*** não há pillar para configuração do TDNS ***'

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
{%- if pillar['tdns_settings'] | default(False) or 
       pillar['tdns_zones'] | default(False) or
       pillar['tdns_dhcpscopes'] | default(False) or
       pillar['tdns_zonerecords'] | default(False) %}
include:
{%- if pillar['tdns_settings'] | default(False) %}
  # server settings
  - apps.tdns.settings
{%- endif %}
{%- if pillar['tdns_zones'] is defined %}
  # dns authoritative zones
  - apps.tdns.zones
{%- endif %}
{%- if pillar['tdns_dhcpscopes'] is defined %}
  # dhcp scopes definition
  - apps.tdns.dhcpscopes
{%- endif %}
{%- if pillar['tdns_zonerecords'] is defined %}
  # zone resource records
  - apps.tdns.zonerecords
{%- endif %}

{%- endif %} # pillar tdns_{all}

{%- endif %} # tdns is defined
