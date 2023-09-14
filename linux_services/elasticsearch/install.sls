#
# adds elasticsearch repo
{% if grains['os_family'] == 'Debian' %}
/etc/apt/trusted.gpg.d/elasticsearch.gpg:
  file.managed:
    - source: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - skip_verify: True
    - makedirs: True

add elasticsearch repo:
  pkgrepo.managed:
    - name: "deb [signed-by=/etc/apt/trusted.gpg.d/elastichsearch.gpg arch=amd64] http://artifacts.elastic.co/packages/8.x/apt stable main"
    - humanname: Elasticsearch repository for 8.x packages
    - dist: stable
    - file: /etc/apt/sources.list.d/elasticsearch.list
    - key_url: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - aptkey: False
    - require:
      - file: /etc/apt/trusted.gpg.d/elasticsearch.gpg
{% elif grains['os_family'] == 'RedHat' %}
# I don't know if this is needed or not in version 8
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

# installs elasticsearch
elastic_install:
  pkg.installed:
    - pkgs:
      - elasticsearch
    - require:
      - add elasticsearch repo

