#
## squid.sls - instala e configura o serviço squid em um mínion
#

squid:
  pkg.installed

/etc/squid/squid.conf:
  file.managed:
    - source: salt://files/services/squid.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0644
    - require:
      - pkg: squid

{% if pillar['squid']| default(False) and pillar['squid']['ssl_enable'] | default(False) %}
/etc/squid/ssl/chain.pem:
  file.managed:
    - source: {{ salt.sslfile.chain() }}
    - user: root
    - group: root
    - mode: 0644
    - makedirs: true

/etc/squid/ssl/cert+key.pem:
  file.managed:
    - source: {{ salt.sslfile.fullchain() }}
    - user: root
    - group: root
    - mode: 0644
    - makedirs: true

append key to cert+key.pem:
  file.append:
    - name: /etc/squid/ssl/cert+key.pem
    - source: {{ salt.sslfile.privkey() }}

{% endif %}

squid.service:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/squid/squid.conf

