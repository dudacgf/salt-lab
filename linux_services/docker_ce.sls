#
## docker_ce.sls - instala docker_ce
#
#    - name: 'deb [arch=$(dpkg --print-architecture)] https://download.docker.com/linux/debian $(lsb_release -cs) stable'


{% if not grains.get('flag_docker_repo_set', False) %}

{% if grains['os'] == 'Debian' %}

docker_repo:
  pkgrepo.managed:
    - name: 'deb https://download.docker.com/linux/debian bullseye stable'
    - humanname: docker-ce repository
    - file: /etc/apt/sources.list.d/docker-ce.list
    - key_url: https://download.docker.com/linux/debian/gpg

{% elif grains['os'] in ['Ubuntu', 'Mint'] %}

docker_repo:
  pkgrepo.managed:
    - name: 'deb https://download.docker.com/linux/ubuntu jammy stable'
    - humanname: docker-ce repository
    - file: /etc/apt/sources.list.d/docker-ce.list
    - key_url: https://download.docker.com/linux/ubuntu/gpg

{% elif grains['os_family'] == 'RedHat' %}

docker_repo:
  pkgrepo.managed:
    - name: docker-ce-stable
    - enabled: True
    - baseurl: https://download.docker.com/linux/centos/$releasever/$basearch/stable
    - enabled: 1
    - gpgcheck: 1
{% else  %}

failure:
  test.fail_without_changes:
    - name: '*** OS não suportado. abandonando.'
    - failhard: True

{% endif %}

flag_docker_repo_set:
  grains.present:
    - value: True
    - require:
      - docker_repo

{% else %}

docker_repo:
  test.show_notification:
    - text: 'docker-ce repo já instalado'

{% endif %} # flag docker repo set

instala docker:
  pkg.installed:
    - pkgs:
      - docker-ce 
      - docker-ce-cli 
      - containerd.io
    - refresh: True
    - require:
      - docker_repo

docker.service:
  service.running:
    - enable: True
    - restart: True
    - require:
      - pkg: instala docker

{% set userlist = pillar.get('users_to_create', {}) %}
{% for user in userlist %}
{% set grouplist = salt['pillar.get']('users_to_create:' + user + ':groups', {}) %}
{% if 'adm' in grouplist %}
add_{{ user }}_docker_group:
  group.present:
    - name: docker
    - addusers:
      - {{ user }}
{% endif %}
{% endfor %}


