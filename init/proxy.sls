## proxy.sls - configuração de proxy para vários serviços
#
## (c) ecgf - jun/2021 - dez/2022
#

{% if pillar['proxy'] | default('none') != 'none' %}
{% set proxy = pillar['proxy'] %}
{% if grains['os_family'] == 'Debian' %}
/etc/apt/apt.conf.d/00-proxy.conf:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - backup: minion
    - contents: [
        'Acquire::http::Proxy "{{ proxy }}";',
        'Acquire::https::Proxy "{{ proxy }}";',
      ]
{% elif grains['os_family'] == 'RedHat' %}
yum-utils:
  pkg.installed

add_proxy_line:
  cmd.run:
    - name: yum-config-manager --setopt=proxy={{ proxy }} --save
    - unless: grep {{ proxy }} /etc/yum.conf
    - require:
      - pkg: yum-utils

{% else %}
proxy error:
  test.show_notification:
    - text: '*** OS não suportado ***'  
{% endif %}

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
'-- Este servidor não usa proxy. nada a fazer'
  test.nop

{% endif %}
