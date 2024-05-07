
{%- import_yaml "maps/pkg_data/by_os_family.yaml" as pkg_data %}
{%- set pkg_data = salt.grains.filter_by(pkg_data) %}

{% if salt.pkg.info_installed(pkg_data.apache.name) %}
#
# apache proxy conf
{{ pkg_data.apache.confd_dir }}/tdns.conf:
  file.managed:
    - source: salt://files/services/apache/tdns.conf
    - user: {{ pkg_data.apache.user }} 
    - group: {{ pkg_data.apache.group }}
    - onlyif:
      - fun: pkg.info_installed
        args: 
          - {{ pkg_data.apache.name }}

{% if grains['os_family'] == 'Debian' %}
a2enconf tdns:
  cmd.run:
    - onlyif:
      - fun: pkg.info_installed
        args: 
          - {{ pkg_data.apache.name }}
    
{% endif %}

{{ pkg_data.apache.service }}:
  service.running:
    - restart: True
    - watch:
      - file: {{ pkg_data.apache.confd_dir }}/tdns.conf
    - onlyif:
      - fun: pkg.info_installed
        args: 
          - {{ pkg_data.apache.name }}

{% endif %} # pkg.info_installed

