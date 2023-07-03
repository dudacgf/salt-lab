{% if 'apache' in pillar['services'] | default([]) %}
#
# apache proxy conf
{{ pillar['pkg_data']['apache']['confd_dir'] }}/gsad.conf:
  file.managed:
    - source: salt://files/services/gvm/apache-gsad-proxy.conf
    - user: {{ pillar['pkg_data']['apache']['user'] }} 
    - group: {{ pillar['pkg_data']['apache']['group'] }}

{% if grains['os_family'] == 'Debian' %}
a2enconf gsad:
  cmd.run
{% endif %}

{{ pillar['pkg_data']['apache']['service'] }}:
  service.running:
    - restart: True
    - watch:
      - file: {{ pillar['pkg_data']['apache']['confd_dir'] }}/gsad.conf

{% endif %} # 'apache' in services

