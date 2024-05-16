{% if 'apache' in pillar['services'] | default([]) %}

{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
#
# apache proxy conf
{{ pkg_data.apache.confd_dir }}/gsad.conf:
  file.managed:
    - source: salt://files/services/gvm/apache-gsad-proxy.conf
    - user: {{ pkg_data.apache.user }} 
    - group: {{ pkg_data.apache.group }}

{% if grains['os_family'] == 'Debian' %}
a2enconf gsad:
  cmd.run
{% endif %}

{{ pkg_data.apache.service }}:
  service.running:
    - restart: True
    - watch:
      - file: {{ pkg_data.apache.confd_dir }}/gsad.conf

{% endif %} # 'apache' in services

