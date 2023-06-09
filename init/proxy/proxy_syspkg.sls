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
/etc/dnf/dnf.conf:
  file.append:
    - text:
      - proxy={{ proxy }}

{% else %}
proxy error:
  test.show_notification:
    - text: '*** OS não suportado ***'  
{% endif %}

{% else %}
'-- Este servidor não usa proxy. nada a fazer':
  test.nop

{% endif %}
