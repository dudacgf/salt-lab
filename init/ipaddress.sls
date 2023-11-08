#!jinja|yaml
#
## ipaddress.sls - sets ipv4 addressing 
#
# ecgf - setembro/2022,outubro/2023
#

{%- if pillar['interfaces'] is not defined or not 
       pillar['redefine_interfaces'] | default(False) %}
{#- get values defined at pillar root and then any values from pillar interface #}
  {%- set nic = grains['hwaddr_interfaces'] | difference(['lo']) | first %}
  {%- set interfaces = {'default': {
                                    'dhcp': pillar['dhcp'],
                                    'ip4_address': pillar['ip4_address'] | default(''),
                                    'ip4_gateway': pillar['ip4_gateway'] | default(''),
                                    'ip4_dns': pillar['ip4_dns'] | default([]),
                                    'hwaddr': grains['hwaddr_interfaces'][nic],
                                   }
                       }
  %}
  {%- do interfaces.update(pillar['interfaces'] | default({})) %}
{%- else %}
{#- one or more nics defined at pillar interfaces dict #}
  {% set interfaces = pillar['interfaces'] | default([]) %}
{%- endif %}

# initializes the flag. it's ugly. It works
flag_not_dhcp:
  grains.present:
    - name: flag_not_dhcp
    - value: False

{%- for network in interfaces | default([]) %}
  {%- set this_nic = interfaces[network] %}
  {%- if not this_nic['dhcp'] | default(True) %}
{{ network }} flag_not_dhcp:
  grains.present:
    - name: flag_not_dhcp
    - value: True
    {%- set ip4_address = this_nic['ip4_address'] %}
    {%- set ip4_gateway = this_nic['ip4_gateway'] | default('') %}
    {%- set ip4_dns = ';'.join(this_nic['ip4_dns'] | default([])) %}
    {%- set nic = salt.ifaces.get_iface_name(this_nic['hwaddr']) %}
    #if i don't have a real hardware address
    {%- if nic is none %} 
        {%- set nic = network %}
        {%- set hwaddr = grains['hwaddr_interfaces'][nic] %}
    {%- endif %}
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
            address1={{ ip4_address + ',' + ip4_gateway }}
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
    - name: /bin/bash -c 'sleep 9; shutdown -r now'
    - bg: True
    - onlyif:
        - fun: match.grain
          tgt: 'flag_not_dhcp:True'

"salt/minion/{{ grains['id'] }}/start":
  event.send:
    - data: '=== all interfaces use dhcp. no ip address to set ==='
    - onlyif:
        - fun: match.grain
          tgt: 'flag_not_dhcp:False'

remove flag_not_dhcp:
  module.run:
    - grains.delkey:
      - key: flag_not_dhcp
