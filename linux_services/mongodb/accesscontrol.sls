#
# Access Control
{%- if not pillar['mongodb']['auth'] | default(False) %}
mongodb access control nothing to do:
  test.show_notification:
    - text: '*** mongodb não usa authorization. nada a fazer ***'
{%- else %}
{%- if not pillar['flag_mongodb_acctl_set'] | default(False) %}
/tmp/mongodb_access_control.mql:
  file.managed:
    - user: mongod
    - group: mongod
    - contents: 
      - 'use admin;'
      - 'db.createUser('
      - '  {'
      - '    user: "{{ pillar['mongodb']['admin_user'] }}",'
      - '    pwd: "{{ pillar['mongodb']['admin_pw'] }}",'
      - '    roles: [ { role: "root", db: "admin" } ]'
      - '  }'
      - ')'
      - 'exit'

configura acl:
  cmd.run:
    - name: 'mongosh --quiet < /tmp/mongodb_access_control.mql'
    - require:
      - file: /tmp/mongodb_access_control.mql

ajusta mongod.conf:
  file.replace:
    - name: /etc/mongod.conf
    - pattern: '^#security:'
    - repl: 'security.authorization: enabled'
    - require:
      - cmd: configura acl

flag_mongodb_acctl_set:
  grains.present:
    - value: True
    - require:
      - file: ajusta mongod.conf

reinicia mongod service acctl:
  service.running:
    - name: mongod.service
    - restart: True
{%- endif %} # mongodb:flag_mongodb_acctl_set
{%- endif %} # mongodb:auth
