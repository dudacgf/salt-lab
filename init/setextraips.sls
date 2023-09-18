#!jinja|yaml
#
## setipaddress.sls - configura ip fixo para interfaces extras do minion
#
# ecgf - novembro/2022
#

{% if pillar['interfaces'] is not defined or 
      not pillar['interfaces']['redefine'] | default(False) %}

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

{% set interfaces = pillar['interfaces'] | default([]) %}
{% do interfaces.pop('redefine') %}
{% for network in interfaces | default([]) %}
{% if not pillar['interfaces'][network]['dhcp'] | default(False) %}

{%- set cmdSetConIP = salt['nmconn.get_cmdline'](network) %}  
nmcli set ip address {{ network }}:
 cmd.run:
   - name: "{{ cmdSetConIP }}"

desabilita flag tudo ok {{ network }}:
  grains.present:
    - name: flag_tudo_ok
    - value: False
    - onfail: 
      - cmd: nmcli set ip address {{ network }}

{% endif %} 
{% endfor %}

flag_static_extra_ips_set:
  grains.present:
    - value: True
    - onlyif:
      - fun: match.grain
        tgt: 'flag_tudo_ok:True'

{% endif %} # flag_static_ip_set
