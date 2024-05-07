{%- import_yaml "maps/pkg_data/by_os_family.yaml" as pkg_data %}
{%- set pkg_data = salt.grains.filter_by(pkg_data) -%}
# instala mariadb-server e roda script que emula mysql_security_installation

mariadb-server:
  pkg.installed

ajusta innodb:
  file.line:
    - name: {{ pkg_data.mariadb.server_conf }}
    - after: 'pid-file.*=.*'
    - mode: insert
    - content: 'innodb_strict_mode=0'
    - require: 
      - pkg: mariadb-server

mariadb.service:
  service.running:
    - enable: true
    - restart: true
    - watch:
      - file: ajusta innodb

{% if not grains.get('flag_mysql_security_run', False) %}
copia mysql security script:
  file.managed:
    - name: /usr/local/bin/mysql_security.sh
    - source: salt://files/scripts/mysql_security.sh
    - user: root
    - group: root
    - mode: 755
    - require:
      - pkg: mariadb-server

executa mysql security script:
  cmd.run:
    - name: /usr/local/bin/mysql_security.sh {{ pillar.mariadb_root_pw }}
    - require:
      - file: copia mysql security script

cleanup:
  cmd.run:
    - name: rm /usr/local/bin/mysql_security.sh
    - require:
      - cmd: executa mysql security script

flag_mysql_security_run:
  grains.present:
    - value: True
    - require:
      - cmd: executa mysql security script

{% endif %}
