{%- import_yaml "maps/pkg_data/by_os_family.yaml" as pkg_data %}
{%- set pkg_data = salt.grains.filter_by(pkg_data) -%}
#
## chrony.sls - instala e configura o serviço chrony para ajuste de horário
# 
chrony:
  pkg.installed
  
# arquivo de configuração
{{ pkg_data.chrony.conf }}:
  file.managed:
    - source: salt://files/services/chrony.conf
    - user: root
    - group: root
    - mode: 644
    - backup: minion

# habilita e inicia o serviço aidecheck.timer
{{ pkg_data.chrony.service }}:
  service.running:
    - enable: true
    - restart: true
    - watch:
      - file: {{ pkg_data.chrony.conf }}

