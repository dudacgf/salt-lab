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

stop mongod:
  service.dead:
    - name: mongod.service

mongod background running:
  cmd.run:
    - name: 'mongod --port 27017 --dbpath /var/lib/mongo/ --pidfilepath /tmp/m.pid 2>&1 > /dev/null'
    - runas: mongod
    - bg: True
    - require:
      - file: /tmp/mongodb_access_control.mql
      - service: stop mongod

configura acl:
  cmd.run:
    - name: 'mongosh --quiet < /tmp/mongodb_access_control.mql'
    - require:
      - cmd: mongod background running

mongod stop background:
  cmd.run:
    - name: 'kill -15 `cat /tmp/m.pid`'

ajusta mongod.conf:
  file.patch:
    - name: /etc/mongod.conf
    - source: salt://files/services/mongod_auth.patch
    - require:
      - cmd: configura acl

flag_mongodb_acctl_set:
  grains.present:
    - value: True

reinicia mongod service acctl:
  service.running:
    - name: mongod.service
    - restart: True
{%- endif %} # mongodb:flag_mongodb_acctl_set
{%- endif %} # mongodb:auth
