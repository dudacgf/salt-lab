{% if not grains['flag_zabbix_mysql_set'] | default(False) %}

{% set root_password = pillar['mariadb_root_pw'] %}
{% set db_name = pillar['zabbix']['db_name'] %}
{% set db_user = pillar['zabbix']['db_user'] %}
{% set db_password = pillar['zabbix']['db_password'] %}
create zabbix db user:
  cmd.script:
    - source: salt://files/scripts/mysql_create_db_user.sh
    - args: {{ root_password }} {{ db_name }} {{ db_user }} '{{ db_password }}'

log_bin_trust 1:
  cmd.run:
    - name: "echo 'set global log_bin_trust_function_creators = 1;' | mysql -uroot -p'{{ root_password }}'"
    - require: 
      - cmd: create zabbix db user

create initial database:
  cmd.run:
    - name: "cat /usr/share/zabbix-sql-scripts/mysql/proxy.sql | mysql --default-character-set=utf8mb4 -u{{ db_user }} -p'{{ db_password }}' {{ db_name }}"
    - require:
      - cmd: log_bin_trust 1

log_bin_trust 0:
  cmd.run:
    - name: "echo 'set global log_bin_trust_function_creators = 0;' | mysql -uroot -p'{{ root_password }}'"

flag_zabbix_mysql_set:
  grains.present:
    - value: True
    - require:
      - cmd: create initial database

{% else %}
'-- zabbix db & user already created':
  test.nop

{% endif %}
