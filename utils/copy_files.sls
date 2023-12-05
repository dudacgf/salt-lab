# copia arquivos, se informados, para a home do usuário

# read map with os_family dependent info
{% import_yaml "maps/users/by_os_family.yaml" as osf %}
{% set osf = salt.grains.filter_by(osf) %}
# read map with users to create and to remove
{% import_yaml "maps/users/users.yaml" as users with context %}

# list of users to create and to remove
{% set users_to_create = users.to_create %}
{% set users_to_remove = users.to_remove + pillar.users_to_remove | default([]) %}
{% set userlist = users_to_create | difference(users_to_remove) %}

{% for user in userlist %}

{% set homefiles = users.to_create[user].homefiles | default([]) %}
{% for file in homefiles %}
    {% set source = users.to_create[user].homefiles[file] %}
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
{% set source = users.to_create[user].ssh_authorized_key | default(False) %}
{% if source %}
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
