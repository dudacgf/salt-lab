#
## setipaddress.sls - configura ip fixo para interfaces extras do minion
#
# ecgf - novembro/2022
#

{% if not grains.get('flag_static_extras_ip_set', False) %}

# a lista de IPs extras está no pillar sob 'interfaces'
{% set interfaces = pillar['interfaces'] %}
{% for network in interfaces %}

   {% if not pillar['interfaces'][network]['dhcp'] | default(False) %}

     {% set hwaddr = pillar['interfaces'][network]['hwaddr'] | default('none') %}
     {% if hwaddr != 'none' %}
        {%- set ip4_address = pillar['interfaces'][network]['ip4_address'] %}
        {%- set ip4_t =  pillar['interfaces'][network]['ip4_netmask'] %}
        {%- set ip4_netmask = salt['network.calc_net']( ip4_address, ip4_t) | regex_replace('(.*/)', '') | string %}
        {%- set nic = salt['ifaces.get_iface_name'](hwaddr) %}
        {%- set connUUID = salt['nmconn.get_uuid'](nic) %}
        {%- set cmdSetConIP = "nmcli con mod '" + connUUID + "' ipv4.address " + ip4_address + "/" + ip4_netmask + " ipv4.method manual" %}

nmcli set ip address {{ nic }}:
 cmd.run:
  - name: "{{ cmdSetConIP }}"

nmcli reapply {{ nic }}:
 cmd.run:
  - name: nmcli device reapply {{ nic }}

     {% endif %} #hwaddr
  {% endif %} # dhcp

{% endfor %}

flag_static_extra_ips_set:
  grains.present:
    - value: True
    - require: 
      - cmd: nmcli reapply*
{% else %}

'*** IP já fixado. nada a fazer ***':
  test.nop

{% endif %} # flag_static_ip_set
