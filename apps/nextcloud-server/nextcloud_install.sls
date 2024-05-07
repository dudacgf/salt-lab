# instala smbclient para poder utilizar o files_external apontando para um fileserver windows/smb
{% if grains['os_family'] == 'RedHat' %}
samba-client:
  pkg.installed
{% elif grains['os_family'] == 'Debian' %}
smbclient:
  pkg.installed
{% else %}
os failure:
  test.fail_without_changes:
    - name: '**** OS Not Supported Yet ****'
    - failhard: true
{% endif %}

# descarrega o site
nextcloud download:
  archive.extracted:
    - name: /var/www/
    - source: https://download.nextcloud.com/server/releases/latest.zip
    - skip_verify: True
    - user: {{ pkg_data.apache.user }}
    - group: {{ pkg_data.apache.group }}
    - unless: test -f /var/www/nextcloud/occ

{% if not grains['flag_nextcloud_users'] | default(False) %}
# inicializa serviço
{% set root_password = pillar['mariadb_root_pw'] %}
{% set db_name = pillar['nextcloud']['db_name'] %}
{% set db_user = pillar['nextcloud']['db_user'] %}
{% set db_password = pillar['nextcloud']['db_password'] %}

nextcloud cria db e user:
  cmd.script:
    - source: salt://files/scripts/mysql_create_db_user.sh
    - args: {{ root_password }} {{ db_name }} {{ db_user }} '{{ db_password }}'

nextcloud initialize:
  cmd.run:
    - name: echo "{{ pillar['nextcloud']['admin_password'] }}" | php /var/www/nextcloud/occ maintenance:install --database "mysql" --database-name '{{ db_name }}' --database-user '{{ db_user }}' --database-pass '{{ db_password }}'
    - runas: {{ pkg_data.apache.user }}

nextcloud create admin:
  cmd.run:
    - name: php /var/www/nextcloud/occ user:add --password-from-env --group admin --display-name {{ pillar['nextcloud']['admin_user'] }} {{ pillar['nextcloud']['admin_user'] }}
    - runas: {{ pkg_data.apache.user }}
    - env: 
      - OC_PASS: '{{ pillar['nextcloud']['admin_password'] }}'

flag_nextcloud_users:
  grains.present:
    - value: True
{% endif %}
