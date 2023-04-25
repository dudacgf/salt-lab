# copia arquivos, se informados, para a home do usuário
{% set users_to_create = pillar.get('users_to_create', {}) %}
{% set users_to_remove = pillar.get('users_to_remove', {}) %}
{% set userlist = users_to_create | difference(users_to_remove) %}

{% for user in userlist %}

{% set homefiles = salt['pillar.get']( 'users_to_create:' + user + ':homefiles', {}) %}
{% for file in homefiles %}
{% set source = salt['pillar.get']('users_to_create:' + user + ':homefiles:' + file, '') %}

"~{{ user }}/{{ file }}":
  file.managed:
    - source: {{ source }}
    - user: {{ user }}
    - group: {{ user }}
    {% if source | regex_match('^.*\.jinja$', ignorecase=True) != None %}
    - template: jinja
    {% endif %}
    - mode: 640
    - backup: minion

{% endfor %} # file in homefiles

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

{% endfor %} # user in userlist
