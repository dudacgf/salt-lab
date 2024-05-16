
{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
#
## nrpe.sls - instala e configura o serviço nrpe para monitoramento via nagios
#

{% if pillar['nrpe_install'] | default(False) %}
{% set settings = pkg_data.nrpe %}

{{ settings.name }}:
  pkg.installed
  
install_plugins:
  pkg.installed:
   - pkgs: [ {{ settings.install_plugins }} ]
  
# copia configuração padrão para o diretório nagios
/etc/nagios/nrpe.cfg:
  file.managed:
    - source: salt://files/services/nrpe.cfg.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - backup: minion

# copia checks não oficiais
{{ settings.plugins_dir }}check_mem.pl:
  file.managed:
    - source: salt://files/services/nrpe_checks/check_mem.pl
    - user: root
    - group: root
    - mode: 755
    - backup: minion

# copia checks não oficiais
{{ settings.plugins_dir }}check_apt_boot:
  file.managed:
    - source: salt://files/services/nrpe_checks/check_apt_boot
    - user: root
    - group: root
    - mode: 755
    - backup: minion

{{ settings.plugins_dir }}check_version:
  file.managed:
    - source: salt://files/services/nrpe_checks/check_version
    - user: root
    - group: root
    - mode: 755
    - backup: minion

{{ settings.plugins_dir }}check_systemd.py:
  file.managed:
    - source: salt://files/services/nrpe_checks/check_systemd.py
    - user: root
    - group: root
    - mode: 755
    - backup: minion

{{ settings.plugins_dir }}check_dns_secondary:
  file.managed:
    - source: salt://files/services/nrpe_checks/check_dns_secondary
    - user: root
    - group: root
    - mode: 755
    - backup: minion

{{ settings.plugins_dir }}check_updates:
  file.managed:
    - source: salt://files/services/nrpe_checks/check_updates
    - user: root
    - group: root
    - mode: 755
    - backup: minion

{% if grains['os_family'] == 'RedHat' and pillar['selinux_mode'] | lower == 'enforced' %}
install nrpe selinux context:
  pkg.installed:
    - name: nrpe-selinux

set selinux context:
  cmd.run:
    - name: restorecon -Rv {{ settings.plugins_dir }}
{% endif %}

{% if grains['os_family'] == 'RedHat' %}
# habilita portas 
nrpe abre porta firewalld:
  firewalld.present:
    - name: public
    - ports: [ '5666/tcp' ]

{% endif %}

#
# sudo directive to run check_updates as root (better results)
/etc/sudoers.d/10-nrpe:
  file.managed:
    - contents: |
       #
       ## Allows nrpe to run check_update as root command
       nrpe  ALL=(ALL)   NOPASSWD: {{ settings.plugins_dir }}check_updates
       nrpe  ALL=(ALL)   NOPASSWD: {{ settings.plugins_dir }}check_apt
       nrpe  ALL=(ALL)   NOPASSWD: {{ settings.plugins_dir }}check_apt_boot

#
# enables and restart if needed (changes in nrpe.cfg)
{{ settings.service }}:
  service.running:
    - enable: true
    - restart: true
    - watch:
      - file: /etc/nagios/nrpe.cfg
    
{% else %} # if pillar[nrpe_install]
'-- nrpe will not be installed':
  test.nop
{% endif %}
