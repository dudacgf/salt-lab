{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
/etc/named.conf:
  file.managed:
    - source: salt://files/services/named/named.conf.jinja
    - template: jinja
    - user: root
    - group: {{ pkg_data.named.group }}
    - mode: 640

{{ pkg_data.named.service }}:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/named.conf
      
