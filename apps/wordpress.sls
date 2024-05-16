#
## wordpress.sls - configura db e restaura backup de site wordpress
#
# ecgf - Outubro/2022

{% set hostname = grains.id.split('.')[0] %}
{% set location = pillar['location'] %}
{% set domain = salt['pillar.get'](location + '_domain') %}
{% set domainname = hostname + '.' + domain %}

{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}

# configura envvar tempdir para o caso da partição /tmp ter sido montada com noexec
# {{ salt['sdb.set']('sdb://osenv/TEMP', '/root') }}

{% set wordpress_sites = pillar.get('wordpress', []) %}
{% for wp_site in wordpress_sites %}

{% if not salt['grains.get']('flag_wordpress_' + wp_site, False) %}

{% set root_password = pillar['mariadb_root_pw'] %}
{% set db_name = pillar['wordpress'][wp_site]['db_name'] %}
{% set db_user = pillar['wordpress'][wp_site]['db_user'] %}
{% set db_password = pillar['wordpress'][wp_site]['db_password'] %}

{{ wp_site }} cria db e user:
  cmd.script:
    - source: salt://files/scripts/mysql_create_db_user.sh
    - args: {{ root_password }} {{ db_name }} {{ db_user }} '{{ db_password }}'

{{ wp_site }} descarrega site:
  archive.extracted:
    - name: /var/www/html
    - source: salt://files/wordpress/{{ wp_site }}.tar.gz
    - user: {{ pkg_data.apache.user }}
    - group: {{ pkg_data.apache.group }}
    - trim_output: 10
    - require:
      - cmd: {{ wp_site }} cria db e user

{{ wp_site }} copia db backup:
  file.managed:
    - name: /tmp/db_backup.sql
    - source: {{ pillar['wordpress'][wp_site]['site_sql'] }}
    - user: root
    - group: root
    - mode: 400
    - require:
      - cmd: {{ wp_site }} cria db e user
      - archive: {{ wp_site }} descarrega site

{{ wp_site }} restaura db data:
  cmd.run:
    - name: mysql --user={{ db_user }} --password={{ db_password }} --database={{ db_name }} < /tmp/db_backup.sql
    - require:
      - file: {{ wp_site }} copia db backup

{{ wp_site }} ajusta urls:
  cmd.script:
    - source: https://github.com/wp-cli/wp-cli/releases/download/v2.6.0/wp-cli-2.6.0.phar
    - args: --path=/var/www/html/{{ wp_site }} search-replace {{ pillar['wordpress'][wp_site]['site_orig_url'] }} {{ domainname }}
    - runas: {{ pkg_data.apache.user }}
    - env: 
      - TEMP: /root
    - cwd: /root
    - require:
      - cmd: {{ wp_site }} restaura db data

{{ wp_site }} ajusta permalinks:
  cmd.script:
    - source: https://github.com/wp-cli/wp-cli/releases/download/v2.6.0/wp-cli-2.6.0.phar
    - args: --path=/var/www/html/{{ wp_site }} option update permalink_structure ''
    - runas: {{ pkg_data.apache.user }}
    - env: 
      - TEMP: /root
    - cwd: /root
    - require:
      - cmd: {{ wp_site }} restaura db data

{{ wp_site }} remove db backup:
  file.absent:
    - name: /tmp/db_backup.sql
    - require:
      - file: {{ wp_site }} copia db backup

flag_wordpress_{{ wp_site }}:
  grains.present:
    - value: True
    - require: 
      - cmd: {{ wp_site }} ajusta urls
      - cmd: {{ wp_site }} ajusta permalinks

{% endif %}
{% endfor %}
