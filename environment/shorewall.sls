#
### shorewall.sls - instala e configura shorewall - iptables/nftables firewall
#
# ecgf - dez/2022
#

{% if pillar['shorewall'] | default('none') == 'none' %}
nothing to do:
  test.show_notification:
    - text: '*** shorewall not enabled for this minion. nothing to do. ***'
{% else %}
{% if grains['os_family'] == 'RedHat' %}
transfere shorewall-core rpm:
  file.managed:
    - name: /tmp/shorewall.rpm
    - source: salt://files/installers/shorewall-5.2.8-0base.noarch.rpm
    - user: root
    - unless: test -f /etc/shorewall/zones

transfere shorewall rpm:
  file.managed:
    - name: /tmp/shorewall-core.rpm
    - source: salt://files/installers/shorewall-core-5.2.8-0base.noarch.rpm
    - user: root
    - unless: test -f /etc/shorewall/zones

instala shorewall:
  cmd.run:
    - name: dnf install /tmp/shorewall* -y -q
    - unless: test -f /etc/shorewall/zones
    - require:
      - file: transfere shorewall*
{% elif grains['os_family'] == 'Debian' %}
instala shorewall:
  pkg.installed:
    - name: shorewall
{% endif %}

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
{% endif %}
