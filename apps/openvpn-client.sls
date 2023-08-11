#
### openvpn-client.sls - installs and configure a openvpn client 
#
#

{%- set srvc = pillar['openvpn-client']['name'] | default('none') %}
{% if srvc != 'none' %}

openvpn:
  pkg.installed

openvpn.service:
  service.dead:
    - enable: False
    - require:
      - pkg: openvpn

/etc/openvpn/{{ srvc }}.crt:
  file.managed:
    - source: salt://files/services/openvpn-client/{{ srvc }}/{{ srvc }}.crt
    - user: root
    - group: root
    - mode: 640
    - require:
      - service: openvpn.service

/etc/openvpn/{{ srvc }}.key:
  file.managed:
    - source: salt://files/services/openvpn-client/{{ srvc }}/{{ srvc }}.key
    - user: root
    - group: root
    - mode: 640
    - require:
      - service: openvpn.service

/etc/openvpn/{{ srvc }}.conf:
  file.managed:
    - source: salt://files/services/openvpn-client/{{ srvc }}/{{ srvc }}.conf
    - user: root
    - group: root
    - mode: 600
    - require:
      - service: openvpn.service

/etc/openvpn/ca.crt:
  file.managed:
    - source: salt://files/services/openvpn-client/{{ srvc }}/ca.crt
    - user: root
    - group: root
    - mode: 640
    - require:
      - service: openvpn.service

/etc/openvpn/ta.key:
  file.managed:
    - source: salt://files/services/openvpn-client/{{ srvc }}/ta.key
    - user: root
    - group: root
    - mode: 640
    - require:
      - service: openvpn.service

systemctl daemon-reload:
  cmd.run:
    - require:
      - file: /etc/openvpn/*

openvpn@{{ srvc }}.service:
  service.running:
    - enable: True
    - restart: True
    - require:
      - cmd: systemctl daemon-reload

{% endif %} 

