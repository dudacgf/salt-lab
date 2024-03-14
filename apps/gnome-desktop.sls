# read map with os_family dependent info
{% import_yaml "maps/users/by_os_family.yaml" as osf %}
{% set osf = salt.grains.filter_by(osf) %}

# read map with users to create and to remove
{% set usermap = pillar.usermap | default('users') %}
{% import_yaml "maps/users/"  + usermap + ".yaml" as users with context %}

# list of users to create and to remove (if a minion needs extra users, they can be defined in the pillar)
{% set users_to_create = users.to_create %}
{% set users_to_remove = users.to_remove + pillar.users_to_remove | default([]) %}
{% set userlist = users_to_create | difference(users_to_remove) %}

{% if grains['os'] == 'Ubuntu' %}
instala gnome:
  pkg.installed:
    - pkgs: [ vanilla-gnome-desktop, vanilla-gnome-default-settings, gdm3 ]

ubuntu gnome remove snapd de novo:
  pkg.removed:
    - name: snapd

{% elif grains['os'] == 'Debian' %}
instala gnome:
  pkg.installed:
    - pkgs: [ gnome ]

{% elif grains['os_family'] == 'RedHat' %}
instala gnome:
   pkg.group_installed:
     - name: GNOME

habilita desktop:
  cmd.run:
    - name: systemctl set-default graphical

{% endif %}

{% for user in userlist %}
   {% set system_account = user.system_account | default(False) %}

{{ user }} gdm3 Account:
  file.managed:
    - name: /var/lib/AccountsService/users/{{ user }}
    - makedirs: true
    - contents: 
      - '[User]'
      - 'SystemAccount={{ system_account | string | lower }}'
    - require:
      - pkg: instala gnome

   {% if salt['pillar.get']('users_to_create:' + user + ':icon', '') != '' %}

copia {{ user }} icon:
  file.managed:
    - name: /var/lib/AccountsService/icons/{{ user }}
    - source: salt://files/users/icons/{{ pillar['users_to_create'][user]['icon'] }}
    - user: {{ user }}
    - group: {{ user }}
    - mode: 644
    - require: 
      - file: {{ user }} gdm3 Account

{#
add {{ user }} icon line:
  file.append:
    - name: /var/lib/AccountsService/users/{{ user }}
    - text: 'Icon=~{{ user }}/.face'
    - require:
      - file: copia {{ user }} icon
#}
   {% endif %} # icon


{% endfor %}
