#
# mongodb.sls - instala e configura serviço mongodb 
#

{% if grains['os_family'] == 'Debian' %}
mongodb repo:
  pkgrepo.managed:
    - name: deb http://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse
    - humanname: MongoDB repository 6.0 version
    - file: /etc/apt/sources.list.d/mongodb-org-6.0.list
    - key_url: https://www.mongodb.org/static/pgp/server-6.0.asc
    - aptkey: False
{% elif grains['os_family'] == 'RedHat' %}
mongodb repo:
  pkgrepo.managed:
    - name: mongodb-org-6.0
    - humanname: 'MongoDB Repository'
    - baseurl: https://repo.mongodb.org/yum/redhat/8/mongodb-org/6.0/x86_64/
    - gpgcheck: 1
    - gpgkey: https://www.mongodb.org/static/pgp/server-6.0.asc
{% else %}
mongodb failure:
  test.fail_without_changes:
    - text: '*** mongodb: OS not supported. Will not install ***'
    - failhard: True
{% endif %}

mongodb install:
  pkg.installed:
    - pkgs:
      - mongodb-org
    - require:
      - mongodb repo

mongodb service enable:
  service.running:
    - name: mongod.service
    - enable: True
    - require: 
      - pkg: mongodb install
