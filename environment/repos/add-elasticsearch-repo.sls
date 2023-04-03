#
# Adiciona o repositório do elasticsearch
{% if grains['os_family'] == 'Debian' %}
add elasticsearch repo:
  pkgrepo.managed:
    - name: deb http://artifacts.elastic.co/packages/8.x/apt stable main
    - humanname: Elasticsearch repository for 8.x packages
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
    - baseurl: https://artifacts.elastic.co/packages/8.x/yum
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

