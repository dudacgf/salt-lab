#
## setipaddress.sls - configura ip fixo para o minion, se pillar['dhcp'] == false
#
# ecgf - setembro/2022
#

{% if pillar['dhcp'] | default(True) %}

'*** minion usa dhcp. nada a fazer ***':
  test.nop

{% elif grains['flag_static_ip_set'] | default(False) %}

'*** IP já fixado. nada a fazer ***':
  test.nop

{% else %}

# obtém endereçamento ip como descrito no pillar deste host [pillar/hosts/nome_do_host.sls]
{%- set ip4_address = pillar['ip4_address'] %}
{%- set ip4_netmask = salt['network.calc_net']( pillar['ip4_address'], pillar['ip4_netmask']) | regex_replace('(.*/)', '') | string %}
{%- set ip4_gateway = pillar['ip4_gateway'] %}
{%- set ip4_dns = pillar['ip4_dns'] %}
{%- if pillar['search_domains'] | default(False) %}
   {%- set ip4_dns_search = ' ipv4.dns-search "' + pillar['internal_domain'] + ', ' + pillar['external_domain'] + '"' %}
{%- else %}
   {%- set ip4_dns_search = '' %}
{% endif %}


# seleciona a placa de rede. válido apenas para servidores com 1 única interface
{% set nic = grains['hwaddr_interfaces'] | difference(['lo']) | first %}

#
# obtém o nome da conexão e gera o comando nmcli para fixar o IP
{% set cmdGetConUUID = "nmcli --get-values uuid con show --active " %}
{% set conUUID = salt['cmd.run'](cmdGetConUUID, '') %}
{% set cmdSetConIP = "nmcli con mod '" + conUUID + "' ipv4.address " + ip4_address + "/" + ip4_netmask + " ipv4.gateway " +  
                      ip4_gateway + " ipv4.dns '" +  ip4_dns | join(',') + "' ipv4.method manual" + ip4_dns_search %}

nmcli set ip address:
  cmd.run:
    - name: "{{ cmdSetConIP }}"

nmcli reapply:
  cmd.run:
    - name: nmcli device reapply {{ nic }}
    - require: 
      - cmd: nmcli set ip address

flag_static_ip_set:
  grains.present:
    - value: True
    - require: 
      - cmd: nmcli reapply

restart salt minion:
  cmd.run:
    - name: 'salt-call --local service.restart salt-minion'
    - bg: True
    - require:
      - grains: flag_static_ip_set

{% endif %} 
