isc-dhcp-relay:
  pkg.installed


/etc/default/isc-dhcp-relay:
  file.managed:
    - source: 'salt://files/services/default_isc-dhcp-relay.jinja'
    - template: jinja
    - user: root
    - group: root
    - mode: 644
