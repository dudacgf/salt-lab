{%- import_yaml "maps/pkg_data/by_os_family.yaml" as pkg_data %}
{%- set pkg_data = salt.grains.filter_by(pkg_data) -%}
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
      
