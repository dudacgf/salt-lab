#
### shorewall.sls - instala e configura shorewall - iptables/nftables firewall
#
# ecgf - dez/2022
#

# read map with shorewall rules 
{% set map = pillar.map | default('') %}
{% load_yaml as shorewall %}
{% include "maps/services/shorewall/shorewall_" + map + ".yaml" ignore missing %}
default:
  install: False
{% endload %}
{% set shorewall = salt.grains.filter_by(shorewall, grain='id', default='default') %}

instala shorewall:
  pkg.installed:
    - name: shorewall
    - refresh: True

configura shorewall.conf:
  file.managed:
    - name: /etc/shorewall/shorewall.conf
    - source: salt://files/services/shorewall/shorewall.conf
    - require:
      - instala shorewall

copia file zones:
  file.managed:
    - name: /etc/shorewall/zones
    - source: salt://files/services/shorewall/zones.jinja
    - template: jinja
    - makedirs: True
    - dir_mode: 755
    - user: root
    - group: root
    - mode: 0600

copia file interfaces:
  file.managed:
    - name: /etc/shorewall/interfaces
    - source: salt://files/services/shorewall/interfaces.jinja
    - makedirs: True
    - dir_mode: 755
    - template: jinja
    - user: root
    - group: root
    - mode: 0600

copia file hosts:
  file.managed:
    - name: /etc/shorewall/hosts
    - source: salt://files/services/shorewall/hosts.jinja
    - makedirs: True
    - dir_mode: 755
    - template: jinja
    - user: root
    - group: root
    - mode: 0600

copia file policy:
  file.managed:
    - name: /etc/shorewall/policy
    - source: salt://files/services/shorewall/policy.jinja
    - makedirs: True
    - dir_mode: 755
    - template: jinja
    - user: root
    - group: root
    - mode: 0600

copia file snat:
  file.managed:
    - name: /etc/shorewall/snat
    - source: salt://files/services/shorewall/snat.jinja
    - makedirs: True
    - dir_mode: 755
    - template: jinja
    - user: root
    - group: root
    - mode: 0600

copia file rules:
  file.managed:
    - name: /etc/shorewall/rules
    - source: salt://files/services/shorewall/rules.jinja
    - makedirs: True
    - dir_mode: 755
    - template: jinja
    - user: root
    - group: root
    - mode: 0600

shorewall restart shorewall service:
  service.running:
    - name: shorewall
    - enable: True
    - restart: True
    - watch:
      - file: copia file*

shorewall stop firewalld:
  service.dead:
    - name: firewalld.service
    - enable: False
    - require:
      - service: shorewall restart shorewall service
    - onlyif:
      - fun: match.grain
        tgt: 'os_family:RedHat'

shorewall stop ufw:
  service.dead:
    - name: ufw.service
    - enable: False
    - require:
      - service: shorewall restart shorewall service
    - onlyif:
      - fun: match.grain
        tgt: 'os_family:Debian'

'bash -c "salt-call --local service.restart salt-minion;"': 
  cmd.run:
    - bg: True
    - onlyif:
      - fun: match.grain
        tgt: 'os_family:Debian'
