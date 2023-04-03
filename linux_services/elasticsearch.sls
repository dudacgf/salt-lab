#
# Adiciona o repositório do elasticsearch
{% if grains['os_family'] == 'Debian' %}
add elasticsearch repo:
  pkgrepo.managed:
    - name: deb http://artifacts.elastic.co/packages/7.x/apt stable main
    - humanname: Elasticsearch repository for 7.x packages
    - dist: stable
    - file: /etc/apt/sources.list.d/elasticsearch.list
    - key_url: salt://files/env/GPG-KEY-elasticsearch
{% elif grains['os_family'] == 'RedHat' %}
# força aceitação de sha-1 signed keys
permit sha1 keys:
  cmd.run:
    - name: update-crypto-policies --set LEGACY

add elasticsearch repo:
  pkgrepo.managed:
    - name: elasticsearch
    - enabled: True
    - baseurl: https://artifacts.elastic.co/packages/7.x/yum
    - gpgcheck: 1
    - gpgkey: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - require:
      - cmd: permit sha1 keys
{% else %}
failure:
  test.fail_without_changes:
    - text: '*** elasticsearch: OS not supported. Will not install ***'
    - failhard: True
{% endif %}

# instala o elasticsearch
elastic_install:
  pkg.installed:
    - pkgs:
      - elasticsearch
    - require:
      - add elasticsearch repo

# ajusta o arquivo de configuração
/etc/elasticsearch/elasticsearch.yml:
  file.managed:
    - source: salt://files/services/elasticsearch.yml.jinja
    - template: jinja
    - user: root
    - group: elasticsearch
    - mode: 660
    - backup: minion

{% if pillar['elasticsearch']['ssl_enable'] | default(False) %}
# chaves de criptografia para tráfego com clientes
/etc/elasticsearch/pki/chain.pem:
  file.managed:
    - source: {{ salt.sslfile.chain() }}
    - makedirs: true
    - dir_mode: 770
    - user: root
    - group: elasticsearch
    - mode: 660
    - backup: minion

/etc/elasticsearch/pki/fullchain.pem:
  file.managed:
    - source: {{ salt.sslfile.fullchain() }}
    - makedirs: true
    - dir_mode: 770
    - user: root
    - group: elasticsearch
    - mode: 660
    - backup: minion

/etc/elasticsearch/pki/privkey.pem:
  file.managed:
    - source: {{ salt.sslfile.privkey() }}
    - makedirs: true
    - dir_mode: 770
    - user: root
    - group: elasticsearch
    - mode: 660
    - backup: minion
{% endif %}

# aumenta vm.max_map_count=262120
elasticsearch sysctl:
  file.append:
    - name: /etc/sysctl.conf
    - text: 'vm.max_map_count=262120'

elasticsearch recarrega sysctl:
  cmd.run:
    - name: sysctl -p

# 
# ajusta o serviço elasticsearch
elasticsearch.service:
  service.running:
    - grain: 
      - roles: elastic
    - enable: true
    - restart: true
    - watch: 
      - file: /etc/elasticsearch/elasticsearch.yml

#
# configura as senhas dos usuários padrão
{%- if pillar['elasticsearch']['auth'] | default(False) and not grains['flag_elasticsearch_auth_set'] | default(False) %}
configura elasticsearch passwords:
  cmd.script:
    - source: salt://files/scripts/elasticsearch-setup-passwords.sh
    - template: jinja
    - shell: /bin/bash
    - runas: elasticsearch

#
# desabilita alguns usuários
disable elasticsearch users:
  cmd.script:
    - source: salt://files/scripts/elasticsearch-disable-users.sh
    - template: jinja
    - runas: elasticsearch

flag_elasticsearch_auth_set:
  grains.present:
    - value: True
    - require:
      - cmd: configura elasticsearch passwords
{%- endif %}

#
# finalmente, checa a instalação
#
checa elasticsearch:
  cmd.script:
    - source: salt://files/checks/check_elasticsearch.sh.jinja
    - template: jinja
    - require:
      - service: elasticsearch.service

