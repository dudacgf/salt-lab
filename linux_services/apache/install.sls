#
### apache/config_ssl.sls - configura serviço ssl
#
#

#
## pacotes instalados
instala apache:
  pkg.installed:
    - name: {{ pillar['pkg_data']['apache']['name'] }}

#
## habilita o serviço
habilita apache:
  service.running:
    - name: {{ pillar['pkg_data']['apache']['service'] }}
    - enable: true
    - restart: true
 
flag_apache_installed:
  grains.present:
    - value: True
    - require:
      - service: habilita apache

