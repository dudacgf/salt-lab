#
### shorewall.sls - instala e configura shorewall - iptables/nftables firewall
#
# ecgf - dez/2022
#

{% if pillar['shorewall'] is defined and 
      pillar['shorewall']['install'] | default(False) %}

#
# redhat 8 and up doesn't offer shorewall anymore
{% if grains['os_family'] == 'RedHat' %}
shorewall repo:
  pkgrepo.managed:
    - name: 'copr_shorewall'
    - file: /etc/yum.repos.d/shorewall_copr.repo
    - humanname: Copr repo for shorewall owned by pgfed
    - baseurl: https://download.copr.fedorainfracloud.org/results/pgfed/shorewall/fedora-rawhide-x86_64/
    - gpgcheck: 1
    - gpgkey: https://download.copr.fedorainfracloud.org/results/pgfed/shorewall/pubkey.gpg
    - enabled: 1
{% endif %}

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
    - user: root
    - group: root
    - mode: 0600

copia file interfaces:
  file.managed:
    - name: /etc/shorewall/interfaces
    - source: salt://files/services/shorewall/interfaces.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0600

copia file hosts:
  file.managed:
    - name: /etc/shorewall/hosts
    - source: salt://files/services/shorewall/hosts.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0600

copia file policy:
  file.managed:
    - name: /etc/shorewall/policy
    - source: salt://files/services/shorewall/policy.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0600

copia file snat:
  file.managed:
    - name: /etc/shorewall/snat
    - source: salt://files/services/shorewall/snat.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0600

copia file rules:
  file.managed:
    - name: /etc/shorewall/rules
    - source: salt://files/services/shorewall/rules.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0600

restart shorewall service:
  service.running:
    - name: shorewall
    - enable: True
    - restart: True
    - watch:
      - file: copia file*

stop firewalld:
  service.dead:
    - name: firewalld.service
    - enable: False
    - require:
      - service: restart shorewall service
{% else %}
nothing to do:
  test.show_notification:
    - text: '*** shorewall not enabled for this minion. nothing to do. ***'
{% endif %}
