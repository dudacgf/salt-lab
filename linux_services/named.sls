#
## bind9.sls - instala um servidor bind9
#
## ecgf - ago/2022
#

{{ pillar['pkg_data']['bind']['name'] }}:
  pkg.installed

/etc/named.conf:
  file.managed:
    - source: salt://files/services/named/named.conf.jinja
    - template: jinja
    - user: root
    - group: named
    - mode: 640

{% if named_zones in pillar %}
{% for zone in pillar.named_zones %}
{% if zone['type'] == 'primary' %}

{{ pillar['pkg_data']['bind']['service'] }}:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/named.conf
      
