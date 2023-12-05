#!jinja|yaml
##
#
## basic.sls - estado básico de um servidor linux.
#
## (c) ecgf - Jun/2021
# 
##

#
#
update_inicial:
  pkg.uptodate:
    - refresh: True

# 
# Pacotes sem o qual não vivo
minimal:
  pkg.installed:
    - pkgs:
      #      - bash-completion
      #- {{ pillar['pkg_data']['bindlibs']['name'] }}
      #- {{ pillar['pkg_data']['bindutils']['name'] }}
      #- fortune-mod
      #- mlocate 
      #- {{ pillar['pkg_data']['vim']['name'] }}
{%- if grains['os'] == 'Rocky' and grains['osmajorrelease'] < 9 %}
      - needrestart
{%- endif %}
#- dos2unix
#- traceroute
#- tcpdump
#     - telnet
#     - net-tools
      - wget
      - hostname
      - curl
#      - facter
      - patch
      - tar

#
# Autoremove qualquer pacote que não for mais necessário
{% if grains['os_family'] == 'Debian' %}
apt-get autoremove -y:
  cmd.run
{% elif grains['os_family'] == 'RedHat' and grains['osmajorrelease'] >= 8 %}
dnf autoremove -y:
  cmd.run
{% endif %}

#
# inclui grains definidos via pillar
{% for grain in pillar['grains'] | default({}) %}
basic create {{ grain }}:
  grains.present:
    - name: grain
    - value: {{ pillar['grains']['grain'] | default(False) }}
{% endfor %}

## esse bash.bashrc é necessário para ativar o prompt no gnome-terminal 
## e para ativar o bash-completion
{% if grains['os_family'] == 'Redhat' %}
/etc/bash.bashrc:
  file.managed:
    - source: salt://files/users/bashrc_redhat_etc
    - user: root
    - group: root
    - mode: 644
    - backup: minion
{% endif %}

## cria a primeira versão do db para o comando locate
update_locatedb:
  cmd.run:
    - name: updatedb
    - bg: true

## copia modulos locais
refresh modules:
  saltutil.sync_modules:
    - refresh: True

