#
# reset password for builtin users
# 
{%- if pillar['elasticsearch'] is defined and
       pillar['elasticsearch']['auth'] | default(False) and not 
       grains['flag_elasticsearch_auth_set'] | default(False) %}
  {%- if pillar['elasticsearch']['version'] | default('8.x') == '8.x' %}
     {%- for user in pillar['elasticsearch']['passwords'] | default([]) %}
          {%- set r = 999999 | random_hash('sha512') %}
          {%- set password = pillar['elasticsearch']['passwords'][user] | default(r) %}
          {%- if user == 'elastic' and password == r %}
'=== User elastic must have its password defined ===':
  test.fail_without_changes:
    - failhard: True
               {%- break %}
          {%- else %}
reset {{ user }} password:
  cmd.run:
    - name: 'echo -e "Y\n{{ password }}\n{{ password }}\n" | /usr/share/elasticsearch/bin/elasticsearch-reset-password -u {{ user }} -i -s'
          {%- endif %}
     {%- endfor %}
  {%- else %}
reset all password:
  cmd.script:
    - source: salt://files/scripts/elasticsearch-setup-passwords.sh
    - template: jinja
    - shell: /bin/bash
    - runas: elasticsearch
  {%- endif %} # if version

#
# disable users 
{%- set credentials = 'elastic:' + pillar['elasticsearch']['passwords']['elastic'] %}
disable logstash_system builtin user:
  cmd.run:
    - name: 'curl -k -s -XPUT http://{{ credentials }}@localhost:9200/_security/user/logstash_system/_disable'

disable remote_monitoring_user builtin user:
  cmd.run:
    - name: 'curl -k -s -XPUT http://{{ credentials }}@localhost:9200/_security/user/remote_monitoring_user/_disable'

disable kibana builtin user:
  cmd.run:
    - name: 'curl -k -s -XPUT http://{{ credentials }}@localhost:9200/_security/user/kibana/_disable'

flag_elasticsearch_auth_set:
  grains.present:
    - value: True
    - require:
      - cmd: disable * user
      - cmd: reset * password
{%- else %}
"=== This elasticsearch install will not use authentication (it should) ===":
  test.nop
{%- endif %}

