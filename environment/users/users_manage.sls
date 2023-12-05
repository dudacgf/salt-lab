# read map with os_family dependent info
{% import_yaml "maps/users/by_os_family.yaml" as osf %}
{% set osf = salt.grains.filter_by(osf) %}

# read map with users to create and to remove
{% import_yaml "maps/users/users.yaml" as users with context %}

#
# list of users to create and to remove
{% set users_to_create = users.to_create %}
# 3.9.2022 remove unwanted users from previous list
{% set users_to_remove = users.to_remove + pillar.get('users_to_remove', []) %}
{% set userlist = users_to_create | difference(users_to_remove) %}

{% for user in userlist %}
# create user
{% if user != 'root' %} 
{{ user }}:
  user.present:
    - password: {{ users.to_create[user]['password'] | default('!') }}
    - home: /home/{{ user }}
    - shell: /bin/bash
    - optional_groups: {{ users.to_create[user].groups | default([]) }}
{% endif %}

{% if grains['os_family'] == 'Suse' %}
group.present_{{ user }}_{{ user }}:
 group.present:  
  - name: {{ user }}
  - addusers: 
    - {{ user }}
{% endif %}

# copy files to users home dir
{% set homefiles = users.to_create[user].homefiles | default([]) %}
{% for file in homefiles %}
{% set source = users.to_create[user].homefiles[file] %}
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

# copy ssh authorized_keys
{% set source = users.to_create[user].ssh_authorized_key | default(False) %}
{% if source %}
~{{ user }}/.ssh/authorized_keys:
  file.managed:
    - source: {{ source }}
    - user: {{ user }}
    - group: {{ user }}
    - mode: 400
    - dir_mode: 700
    - makedirs: true
    - backup: minion
{% endif %}
{% endfor %} # user

#
# remove gold image common usernames
{% for user in users.to_remove %}
{{ user }}_delete:
  user.absent:
    - name: {{ user }}
    - purge: True
    - force: True
{% endfor %}

