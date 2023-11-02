#!jinja|yaml
#
## hotspot.sls - setup a wifi ap
#
# ecgf - outubro/2023
#

{%- if pillar['interfaces'] is not defined %}
'=== hotspot settings not found ===':
  test.nop
{% else %}
  {% set interfaces = pillar['interfaces'] %}
  {% do interfaces.pop('redefine') %}
  {%- for nic in interfaces %}
    {%- set this_nic = interfaces[nic] %}
    {%- if this_nic['itype'] == 'hotspot' %}
      {%- set ip4_address = this_nic['ip4_address'] %}
      {%- set ip4_netmask = salt.network.calc_net(ip4_address, this_nic['ip4_netmask']) | regex_replace('(.*/)', '') | string %}
      {%- set ap_name = this_nic['ap_name'] %}
      {%- set ap_psk = this_nic['ap_psk'] %}
{{ ap_name }}.nmconnection:
  file.managed:
    - name: /etc/NetworkManager/system-connections/{{ ap_name }}.nmconnection
    - contents: |
            [connection]
            id={{ ap_name }}
            uuid={{ salt.cmd.run('uuid') }}
            type=wifi
            autoconnect=true
            permissions=
            secondaries=

            [wifi]
            hidden=false
            mac-address={{ this_nic['hwaddr'] }}
            mac-address-blacklist=
            mode=ap
            seen-bssids=
            ssid={{ ap_name }}

            [wifi-security]
            group=ccmp;
            key-mgmt=wpa-psk
            pairwise=ccmp;
            proto=rsn;
            psk={{ ap_psk }}

            [ipv4]
            address={{ ip4_address + '/' + ip4_netmask }}
            dns-search=
            method=shared

            [ipv6]
            dns-search=
            method=auto
    - user: root
    - group: root
    - mode: 600

    {%- endif %} 
  {%- endfor %}
{%- endif %}
