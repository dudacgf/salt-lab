{% if grains['os_family'] == 'RedHat' %}
{%   set sudo_group = 'wheel' %}
{%   set bashrc = 'bashrc_redhat' %}
{% else %}
{%   set sudo_group = 'sudo' %}
{%   set bashrc = 'bashrc_ubuntu' %}
{% endif %}

users_to_create:
  duda:
    password: $6$rounds=656000$IcjDG6VQC5Jqt9A9$GV/C9tJaCetff/O8nkJnoIjgdmWZ9uu6G8v5uZsS11rezQ4tPZHMd3jUR/tKWfexVw/gFTwBUvlLZ.aN9av1C1
    groups: ['adm', "{{ sudo_group }}"]
    homefiles:
      .bashrc: 'salt://files/users/{{ bashrc }}'
      .bashrc_aliases: 'salt://files/users/bashrc_aliases.jinja'
      .bash_profile: 'salt://files/users/bash_profile_user'
      .vimrc: 'salt://files/users/vimrc'
    ssh_authorized_key: 'salt://files/pki/authorized_keys_duda'
    system_account: false
    icon: duda.png
  smtenorio:
    password: $6$rounds=656000$kGr4EJMRp1tlWte/$lT8d.e4YC34piUqcE54oFUet07YT.QH.Bh61vOxMUf50/6/oz4xLqAJEYfquywb16okmGJeJL4HiSdR6MTGRY/
    groups: ['adm', "{{ sudo_group }}"]
    ssh_authorized_key: 'salt://files/pki/authorized_keys_smtenorio'
    system_account: true
  scanacct:
    password: $6$rounds=656000$4EkkP2sPkCiILzxQ$wr0NO2KjRyxYHqbgsXifgs6LW7hPT7h7Ek3EmvRDemvNvWH6oOmxx6tIdisMtNpAkcXAgzhBy3EVZfKAo3cPW.
    groups: ['adm', "{{ sudo_group }}"]
    system_account: true
  root:
    homefiles:
      .bashrc: 'salt://files/users/{{ bashrc }}'
      .bashrc_aliases: 'salt://files/users/bashrc_aliases.jinja'
      .bash_profile: 'salt://files/users/bash_profile_user'
      .vimrc: 'salt://files/users/vimrc'
    ssh_authorized_key: 'salt://files/pki/authorized_keys_root'
    system_account: true

users_to_remove: 
  debian:
  ubuntu:
  rocky:
  odroid:

pkg_apps:
  {% if grains['os_family'] == 'Debian' %}
  sudo:
    '/usr/bin/apt':
    '/usr/bin/apt-get':
  {% elif grains['os_family'] == 'RedHat' %}
  wheel:
    '/usr/bin/dnf':
    '/usr/bin/yum':
    '/usr/bin/rpm':
    '/bin/dnf':
    '/bin/yum':
    '/bin/rpm':
  {% else %}
  nonegroup:
  {% endif %}

