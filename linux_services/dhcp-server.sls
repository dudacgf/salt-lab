#
## dhcp-server.sls - instala e configura um servidor dhcp
#

{{ pillar['pkg_data']['dhcp-server']['name'] }}:
  pkg.installed

/etc/dhcp/dhcpd.conf:
  file.managed:
    - source: salt://files/services/dhcpd_conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0600
    - require:
      - pkg: {{ pillar['pkg_data']['dhcp-server']['name'] }}

/etc/default/isc-dhcp-server:
  file.managed:
    - source: salt://files/services/default-isc-dhcp-server.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0644

{{ pillar['pkg_data']['dhcp-server']['service'] }}:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/dhcp/dhcpd.conf
      - file: /etc/default/isc-dhcp-server

isc_dhcp_leases:
  pip.installed

/usr/local/bin/dhcpd_leases:
  file.managed:
    - source: salt://files/scripts/dhcpd_leases.py
    - user: root
    - group: root
    - mode: 0755
    - require:
      - pip: isc_dhcp_leases

