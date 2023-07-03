## proxy.sls - configuração de proxy para vários serviços
#
## (c) ecgf - jun/2021 - dez/2022
#

{% if pillar['proxy'] | default('none') != 'none' %}
{% set proxy = pillar['proxy'] %}

#
## configura proxy para o salt-minion
/etc/salt/minion.d/00-proxy.conf:
  file.managed:
    - contents:
      - "proxy_host: {{ proxy | regex_replace('^.*://(.*):.*', '\\1') }}"
      - "proxy_port: {{ proxy | regex_replace('.*:(.*)$', '\\1') }}"
      - "no_proxy: [ '127.0.0.1', 'localhost' ]"

setproxy restart salt minion:
  cmd.run:
    - name: 'salt-call --local service.restart salt-minion'
    - bg: True
    - require:
      - file: /etc/salt/minion.d/00-proxy.conf

{% else %}
'-- Este servidor não usa proxy. nada a fazer':
  test.nop

{% endif %}
