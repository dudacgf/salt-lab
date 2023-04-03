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

{{ pillar['pkg_data']['dhcp-server']['service'] }}:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/dhcp/dhcpd.conf

pip3 install isc_dhcp_leases 2> /dev/null:
  cmd.run

/usr/local/bin/dhcpd_leases:
  file.managed:
    - source: salt://files/scripts/dhcpd_leases.py
    - user: root
    - group: root
    - mode: 0755
    - require:
      - cmd: pip3 install*

