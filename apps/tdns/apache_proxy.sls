{% if salt.pkg.info_installed(pillar['pkg_data']['apache']['name']) %}
#
# apache proxy conf
{{ pillar['pkg_data']['apache']['confd_dir'] }}/tdns.conf:
  file.managed:
    - source: salt://files/services/apache/tdns.conf
    - user: {{ pillar['pkg_data']['apache']['user'] }} 
    - group: {{ pillar['pkg_data']['apache']['group'] }}
    - onlyif:
      - fun: pkg.info_installed
        args: 
          - {{ pillar['pkg_data']['apache']['name'] }}

{% if grains['os_family'] == 'Debian' %}
a2enconf tdns:
  cmd.run:
    - onlyif:
      - fun: pkg.info_installed
        args: 
          - {{ pillar['pkg_data']['apache']['name'] }}
    
{% endif %}

{{ pillar['pkg_data']['apache']['service'] }}:
  service.running:
    - restart: True
    - watch:
      - file: {{ pillar['pkg_data']['apache']['confd_dir'] }}/tdns.conf
    - onlyif:
      - fun: pkg.info_installed
        args: 
          - {{ pillar['pkg_data']['apache']['name'] }}

{% endif %} # pkg.info_installed

