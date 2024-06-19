{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
#
## dhcp-server.sls - instala e configura um servidor dhcp
#

{{ pkg_data.dhcp_server.name }}:
  pkg.installed

{{ pkg_data.dhcp_server.conf_file | default('/etc/dhcp/dhcpd.conf') }}:
  file.managed:
    - source: salt://files/services/dhcpd_conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0600
    - require:
      - pkg: {{ pkg_data.dhcp_server.name }}

{{ pkg_data.dhcp_server.sysconf_file | default('/etc/default/isc-dhcp-server:') }}:
  file.managed:
    - source: salt://files/services/default-isc-dhcp-server.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 0644

{{ pkg_data.dhcp_server.service }}:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: {{ pkg_data.dhcp_server.sysconf_file }}
      - file: {{ pkg_data.dhcp_server.conf_file }}

isc_dhcp_leases:
  pip.installed

/usr/local/etc/oui.txt:
  file.managed:
     - source: http://standards-oui.ieee.org/oui.txt
     - skip_verify: True
