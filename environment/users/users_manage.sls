##
# (versão 0.1 mesmo conjunto de grupos para todos os usuários. #TODO# diferenciar grupos por usuários

#
# Obtém a lista de usuários a serem criados e grupos em que eles serão adicionados.
{% set users_to_create = pillar.get('users_to_create', {}) %}
# 3.9.2022 retira da lista usuários a remover
{% set users_to_remove = pillar.get('users_to_remove', {}) %}
{% set userlist = users_to_create | difference(users_to_remove) %}

{% for user in userlist %}

# obtém os atributos desse usuário
{% set password = salt['pillar.get']( 'users_to_create:' + user + ':password', '') %}

# cria esse usuário, se não existir
# usuário root sempre existe, né 
{% if user != 'root' %} 
{{ user }}:
  user.present:
    - password: {{ password }}
    - home: /home/{{ user }}
    - shell: /bin/bash
{% endif %}

# copia arquivos, se informados, para a home do usuário
{% set homefiles = salt['pillar.get']( 'users_to_create:' + user + ':homefiles', {}) %}
{% for file in homefiles %}
{% set source = salt['pillar.get']('users_to_create:' + user + ':homefiles:' + file, '') %}

~{{ user }}/{{ file }}:
  file.managed:
    - source: {{ source }}
    - user: {{ user }}
    - group: {{ user }}
    {% if source | regex_match('^.*\.jinja$', ignorecase=True) != None %}
    - template: jinja
    {% endif %}
    - mode: 640
    - backup: minion
{% endfor %}

# copia a chave pública ssh, se informada, para o diretório .ssh na home do usuário
{% set source = salt['pillar.get']( 'users_to_create:' + user + ':ssh_authorized_key', 'none') %}
{% if source != 'none' %}
~{{ user }}/.ssh/authorized_keys:
  file.managed:
    - source: {{ source }}
    - user: {{ user }}
    - group: {{ user }}
    - mode: 644
    - dir_mode: 700
    - makedirs: true
    - backup: minion
{% endif %}

# insere o usuário na lista de grupos
{% set grouplist = salt['pillar.get']('users_to_create:' + user + ':groups', {}) %}
{% for group in grouplist %}

group.present_{{ user }}_{{ group }}:
 group.present:  
  - name: {{ group }}
  - addusers: 
    - {{ user }}

{% endfor %} # group

{% endfor %} # user

#
# apaga usuários utilizados nas imagens gold
{% set users_to_remove = pillar['users_to_remove'] %}

{% for user in users_to_remove %}
{{ user }}_delete:
  user.absent:
    - name: {{ user }}
    - purge: True
    - force: True
{% endfor %}

