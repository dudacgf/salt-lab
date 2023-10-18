#!jinja|yaml
#
## ipaddress.sls - sets ipv4 addressing 
#
# ecgf - setembro/2022,outubro/2023
#

{%- if pillar['interfaces'] is not defined or not 
       pillar['interfaces']['redefine'] | default(False) %}
# only 1 nic in default virtual network, values defined at pillar root
  {%- set nic = grains['hwaddr_interfaces'] | difference(['lo']) | first %}
  {%- set interfaces = {'default': {
                                    'dhcp': pillar['dhcp'],
                                    'ip4_address': pillar['ip4_address'] | default(''),
                                    'ip4_netmask': pillar['ip4_netmask'] | default(''),
                                    'ip4_gateway': pillar['ip4_gateway'] | default(''),
                                    'ip4_dns': pillar['ip4_dns'] | default([]),
                                    'hwaddr': grains['hwaddr_interfaces'][nic],
                                   }
                       }
  %}
{%- else %}
# one or more nics defined in pillar interface dict
  {% set interfaces = pillar['interfaces'] | default([]) %}
  {% do interfaces.pop('redefine') %}
{%- endif %}

{% for network in interfaces | default([]) %}
  {%- set this_nic = interfaces[network] %}
  {%- if not this_nic['dhcp'] | default(False) %}
    {%- set ip4_address = this_nic['ip4_address'] %}
    {%- set ip4_netmask = salt.network.calc_net(ip4_address, this_nic['ip4_netmask']) | regex_replace('(.*/)', '') | string %}
    {%- set ip4_gateway = this_nic['ip4_gateway'] | default('') %}
    {%- set ip4_dns = ';'.join(pillar['ip4_dns'] | default([])) %}
    {%- set nic = salt.ifaces.get_iface_name(this_nic['hwaddr'])  %}
    {%- set uuid = salt.nmconn.get_uuid(nic) %}
{{ nic }}.nmconnection:
  file.managed:
    - name: /etc/NetworkManager/system-connections/{{ nic }}.nmconnection
    - contents: |
            [connection]
            id={{ nic }}
            uuid={{ uuid }}
            type=ethernet
            autoconnect-priority=-999
            interface-name={{ nic }}
            timestamp={{ salt.cmd.run('date +%s') }}

            [ethernet]

            [ipv4]
            address1={{ ip4_address + '/' + ip4_netmask + ',' + ip4_gateway }}
            dns={{ ip4_dns }}
            method=manual

            [ipv6]
            addr-gen-mode=eui64
            method=auto

            [proxy]

    - user: root
    - group: root
    - mode: 600

  {% endif %} 
{% endfor %}

reboot nmconnection:
  cmd.run:
    - name: /bin/bash -c 'sleep 5; shutdown -r now'
    - bg: True

