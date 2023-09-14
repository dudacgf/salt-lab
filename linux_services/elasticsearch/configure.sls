# temporarily set no xpack security at all
minimal elasticsearch.yml:
  file.managed:
    - name: /etc/elasticsearch/elasticsearch.yml
    - user: root
    - group: elasticsearch
    - contents: |
          http.host: 0.0.0.0
          path.data: /var/lib/elasticsearch
          path.logs: /var/log/elasticsearch
          cluster.initial_master_nodes: ["lgl.shireslab.com.br"]
          xpack.security.enabled: True
          xpack.security.transport.ssl.enabled: false
          xpack.security.http.ssl.enabled: false

# enables and starts the service
elasticsearch.service:
  service.running:
    - enable: True

# if ssl is used, copy certificate and privkey
{% if pillar['elasticsearch'] is defined and 
      pillar['elasticsearch']['ssl_enable'] | default(False) %}
/etc/elasticsearch/ssl/chain.pem:
  file.managed:
    - source: {{ salt.sslfile.chain() }}
    - makedirs: true
    - dir_mode: 770
    - user: root
    - group: elasticsearch
    - mode: 660
    - backup: minion

/etc/elasticsearch/ssl/fullchain.pem:
  file.managed:
    - source: {{ salt.sslfile.fullchain() }}
    - makedirs: true
    - dir_mode: 770
    - user: root
    - group: elasticsearch
    - mode: 660
    - backup: minion

/etc/elasticsearch/ssl/privkey.pem:
  file.managed:
    - source: {{ salt.sslfile.privkey() }}
    - makedirs: true
    - dir_mode: 770
    - user: root
    - group: elasticsearch
    - mode: 660
    - backup: minion
{% endif %}

{% include 'linux_services/elasticsearch/auth.sls' %}

# enlarge vm.max_map_count 
elasticsearch sysctl:
  file.append:
    - name: /etc/sysctl.conf
    - text: 'vm.max_map_count=262120'

elasticsearch recarrega sysctl:
  cmd.run:
    - name: sysctl -p

#
# real configuration file
/etc/elasticsearch/elasticsearch.yml:
  file.managed:
    - source: salt://files/services/elasticsearch.yml.jinja
    - template: jinja
    - user: root
    - group: elasticsearch
    - mode: 660
    - backup: minion

# 
# restarts elasticsearch
restart elasticsearch:
  module.run:
    - name: service.restart
    - m_name: elasticsearch.service
    - watch: 
      - file: /etc/elasticsearch/elasticsearch.yml
