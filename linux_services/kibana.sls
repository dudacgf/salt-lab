# 
#
## kibana.sls - instala e configura o serviço kibana para configuração do elasticsearch
# 

#
# Adiciona o repositório do elasticsearch
{%- if pillar['kibana'] is defined %}
    {%- set version = pillar['kibana']['version'] | default('8.x') %}
{%- endif %}
{% if grains['os_family'] == 'Debian' %}
add elasticsearch repo:
  pkgrepo.managed:
    - name: deb http://artifacts.elastic.co/packages/{{ version }}/apt stable main
    - humanname: Elasticsearch repository for {{ version }} packages
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
    - baseurl: https://artifacts.elastic.co/packages/{{ version }}/yum
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

# instala o kibana
kibana:
  pkg.installed

{%- if grains['os_family'] == 'RedHat' %}
# restore default crypto policy
restore crypto policies:
  cmd.run:
    - name: update-crypto-policies --set DEFAULT
{%- endif %}

# arquivo de configuração do kibana
kibana.yml:
  file.managed:
    - name: /etc/kibana/kibana.yml
    - source: salt://files/services/kibana.yml.jinja
    - template: jinja
    - user: root
    - group: kibana
    - mode: 660
    - backup: minion

{% if pillar['kibana']['ssl_enable'] | default(False) %}
# chaves para tráfego encriptado com o servidor elasticsearch
/etc/kibana/pki/chain.pem:
  file.managed:
    - source: {{ salt.sslfile.chain() }}
    - makedirs: true
    - dir_mode: 770
    - user: root
    - group: kibana
    - mode: 660
    - backup: minion

/etc/kibana/pki/privkey.pem:
  file.managed:
    - source: {{ salt.sslfile.privkey() }}
    - makedirs: true
    - dir_mode: 770
    - user: root
    - group: kibana
    - mode: 660
    - backup: minion

/etc/kibana/pki/cert.pem:
  file.managed:
    - source: {{ salt.sslfile.cert() }}
    - makedirs: true
    - dir_mode: 770
    - user: root
    - group: kibana
    - mode: 660
    - backup: minion
{% endif %}
  
# ajusta portas de firewalld
{% if grains['os_family'] == 'RedHat' %}
kibana firewalld port:
  cmd.run:
    - name: 'firewall-cmd --permanent --add-port=5601/tcp'

kibana firewalld reload:
  cmd.run:
    - name: 'firewall-cmd --reload'

{% endif %}

# ajusta o serviço kibana
kibana.service:
  service.running:
    - enable: true
    - restart: true
    - watch: 
      - file: /etc/kibana/kibana.yml
  
