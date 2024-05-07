{%- set hostname = grains.id.split('.')[0] %}
{%- set domain_type = pillar.get('location', 'internal') %}
{%- set domain = salt['pillar.get'](domain_type + "_domain") -%}

{%- import_yaml "maps/pkg_data/by_os_family.yaml" as pkg_data %}
{%- set pkg_data = salt.grains.filter_by(pkg_data) %}

{{ pkg_data.apache.confd_dir }}/zabbix.conf:
  file.append:
      - text: |
          
          RewriteCond %{HTTP_HOST} ^{{ hostname }}.{{ domain }}$
          RewriteRule "^/?$"      https://%{HTTP_HOST}/zabbix [R=302,L]

systemctl restart {{ pkg_data.apache.service }}:
  cmd.run:
    - watch:
      - file: {{ pkg_data.apache.confd_dir }}/zabbix.conf
