{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
#
### apache/config_ssl.sls - configura serviço ssl
#
#

#
## pacotes instalados
instala apache:
  pkg.installed:
    - name: {{ pkg_data.apache.name }}

#
## habilita o serviço
habilita apache:
  service.running:
    - name: {{ pkg_data.apache.service }}
    - enable: true
    - restart: true
 
flag_apache_installed:
  grains.present:
    - value: True
    - require:
      - service: habilita apache

