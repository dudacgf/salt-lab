#
# adds elasticsearch repo

{%- if pillar['elasticsearch'] is defined %}
    {%- set version = pillar['elasticsearch']['version'] | default('8.x') %}
{%- else %}
    {%- set version = '8.x' %}
{% endif %}
{%- if grains['os_family'] == 'Debian' %}
/etc/apt/trusted.gpg.d/elasticsearch.gpg:
  file.managed:
    - source: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - skip_verify: True
    - makedirs: True

add elasticsearch repo:
  pkgrepo.managed:
    - name: "deb [signed-by=/etc/apt/trusted.gpg.d/elastichsearch.gpg arch=amd64] http://artifacts.elastic.co/packages/{{ version }}/apt stable main"
    - humanname: Elasticsearch repository for {{ version }} packages
    - dist: stable
    - file: /etc/apt/sources.list.d/elasticsearch.list
    - key_url: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - aptkey: False
    - require:
      - file: /etc/apt/trusted.gpg.d/elasticsearch.gpg
{%- elif grains['os_family'] == 'RedHat' %}
# I don't know if this is needed yet (it is)
elastic re-enable sha1:
  cmd.run:
    - name: update-crypto-policies --set DEFAULT:SHA1

add elasticsearch repo:
  pkgrepo.managed:
    - name: elasticsearch
    - enabled: True
    - baseurl: https://artifacts.elastic.co/packages/{{ version }}/yum
    - gpgcheck: 1
    - gpgkey: https://artifacts.elastic.co/GPG-KEY-elasticsearch
    - require:
      - cmd: elastic re-enable sha1
{%- else %}
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

