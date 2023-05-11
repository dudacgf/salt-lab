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

{% set users = pillar['users_to_create'] %}
{% for user in users %}
   {% set system_account = salt['pillar.get']('users_to_create:' + user + ':system_account', False) %}

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
