#
## setipaddress.sls - configura ip fixo para interfaces extras do minion
#
# ecgf - novembro/2022
#

{% if not pillar['redefine_interfaces'] | default(False) %}

'*** minion não redefine interfaces. nada a fazer ***':
  test.nop

{% elif grains['flag_static_extra_ips_set'] | default(False) %}

'*** IP já fixado. nada a fazer ***':
  test.nop

{% else %}

# a lista de IPs extras está no pillar sob 'interfaces'
flag_tudo_ok:
  grains.present:
    - value: True

{% for network in pillar['interfaces'] | default([]) %}

   {% if not pillar['interfaces'][network]['dhcp'] | default(False) %}

     {% set hwaddr = pillar['interfaces'][network]['hwaddr'] | default('none') %}
     {% if hwaddr != 'none' %}
        # monta o comando nmcli para definição IP4 desta interface do minion
        {%- set ip4_address = pillar['interfaces'][network]['ip4_address'] %}
        {%- set ip4_t =  pillar['interfaces'][network]['ip4_netmask'] %}
        {%- set ip4_netmask = salt['network.calc_net']( ip4_address, ip4_t) | regex_replace('(.*/)', '') | string %}
        {%- set ip4_gateway = pillar['interfaces'][network]['ip4_gateway'] | default('') %}
        {%- if ip4_gateway | is_ipv4 %}
           {% set ip4_gateway = ' ipv4.gateway ' + ip4_gateway %}
        {%- endif %}
        {%- set ip4_dns = pillar['interfaces'][network]['ip4_dns'] | default('') %}
        {% if ip4_dns != '' %}
           {% set ip4_dns = ' ipv4.dns ' + ip4_dns | join(',') %}
        {% endif %}
        {%- set nic = salt['ifaces.get_iface_name'](hwaddr) %}
        {%- set connUUID = salt['nmconn.get_uuid'](nic) %}
        {%- set cmdSetConIP = "nmcli con mod '" + connUUID | string + "' ipv4.address " + ip4_address | string + "/" + 
                              ip4_netmask | string + ip4_gateway | string + ip4_dns | string + " ipv4.method manual" %}  

nmcli set ip address {{ nic }}:
 cmd.run:
   - name: "{{ cmdSetConIP }}"

nmcli reapply {{ nic }}:
 cmd.run:
   - name: nmcli device reapply {{ nic }}

desabilita flag tudo ok {{ nic }}:
  grains.present:
    - name: flag_tudo_ok
    - value: False
    - onfail: 
      - cmd: nmcli set ip address {{ nic }}
      - cmd: nmcli reapply {{ nic }}

     {% endif %} #hwaddr

  {% endif %} # dhcp
{% endfor %}

flag_static_extra_ips_set:
  grains.present:
    - value: True
    - onlyif:
      - fun: match.grain
        tgt: 'flag_tudo_ok:True'


reboot setextraips {{ grains['id'].split('.')[0] }}:
  cmd.run:
    - name: /bin/bash -c 'sleep 5; shutdown -r now'
    - bg: True
    - onlyif: 
      - fun: match.grain
        tgt: 'flag_static_extra_ips_set:True'

{% endif %} # flag_static_ip_set
