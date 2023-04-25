{%- set elastic_pw = pillar['elasticsearch']['passwords']['elastic'] %}
{%- set apm_sys_pw = pillar['elasticsearch']['passwords']['apm_system'] %}
{%- set kibana_pw = pillar['elasticsearch']['passwords']['kibana'] %}
{%- set kibanas_pw = pillar['elasticsearch']['passwords']['kibana_system'] %}
{%- set logstash_pw = pillar['elasticsearch']['passwords']['logstash_system'] %}
{%- set beats_s_pw = pillar['elasticsearch']['passwords']['beats_system'] %}
{%- set remote_u_pw = pillar['elasticsearch']['passwords']['remote_monitoring_user'] %}
#!/bin/bash
#
# configura senha para os usuários padrão do elasticsearch
#
echo -e "y\n{{ elastic_pw }}\n{{ elastic_pw }}\n{{ apm_sys_pw }}\n{{ apm_sys_pw }}\n{{ kibana_pw }}\n{{ kibana_pw }}\n{{ kibanas_pw }}\n{{ kibanas_pw }}\n{{ logstash_pw }}\n{{ logstash_pw }}\n{{ beats_s_pw }}\n{{ beats_s_pw }}\n{{ remote_u_pw }}\n{{ remote_u_pw }}\ny\n" | \
  /usr/share/elasticsearch/bin/elasticsearch-setup-passwords interactive

