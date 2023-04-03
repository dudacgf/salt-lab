#
## nrpe.sls - instala e configura o serviço nrpe para monitoramento via nagios
# 
#


{{ pillar['pkg_data']['nrpe']['name'] }}:
  pkg.installed
  
install_plugins:
  pkg.installed:
   - pkgs: [ {{ pillar['pkg_data']['nrpe']['install_plugins'] }} ]
  
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
{{ pillar['pkg_data']['nrpe']['plugins_dir'] }}check_mem.pl:
  file.managed:
    - source: salt://files/services/nrpe_checks/check_mem.pl
    - user: root
    - group: root
    - mode: 755
    - backup: minion

# copia checks não oficiais
{{ pillar['pkg_data']['nrpe']['plugins_dir'] }}check_apt_boot:
  file.managed:
    - source: salt://files/services/nrpe_checks/check_apt_boot
    - user: root
    - group: root
    - mode: 755
    - backup: minion

{{ pillar['pkg_data']['nrpe']['plugins_dir'] }}check_version:
  file.managed:
    - source: salt://files/services/nrpe_checks/check_version
    - user: root
    - group: root
    - mode: 755
    - backup: minion

{{ pillar['pkg_data']['nrpe']['plugins_dir'] }}check_systemd.py:
  file.managed:
    - source: salt://files/services/nrpe_checks/check_systemd.py
    - user: root
    - group: root
    - mode: 755
    - backup: minion

{{ pillar['pkg_data']['nrpe']['plugins_dir'] }}check_dns_secondary:
  file.managed:
    - source: salt://files/services/nrpe_checks/check_dns_secondary
    - user: root
    - group: root
    - mode: 755
    - backup: minion

{{ pillar['pkg_data']['nrpe']['plugins_dir'] }}check_updates:
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
    - name: restorecon -Rv {{ pillar['nrpe']['plugins_dir'] }}
{% endif %}

{% if grains['os_family'] == 'RedHat' %}
# habilita portas 
nrpe abre porta firewalld:
  firewalld.present:
    - name: public
    - ports: [ '5666/tcp' ]

{% endif %}

#
# ajusta o serviço nrpe
{{ pillar['pkg_data']['nrpe']['service'] }}:
  service.running:
    - enable: true
    - restart: true
    - watch:
      - file: /etc/nagios/nrpe.cfg
    
