#
## bind9.sls - instala um servidor bind9
#
## ecgf - ago/2022
#

{{ pillar['pkg_data']['bind']['name'] }}:
  pkg.installed

/etc/named.conf:
  file.managed:
    - source: salt://files/services/bind9/named.conf
    - user: root
    - group: named
    - mode: 640

/etc/named/shireslab.zone.conf:
  file.managed:
    - source: salt://files/services/bind9/shireslab.zone.conf
    - user: root
    - group: named
    - mode: 640

/var/named/data/zones/shireslab.com.dns:
  file.managed:
    - source: salt://files/services/bind9/shireslab.com.dns
    - user: root
    - group: named
    - mode: 640
    - makedirs: True
    - dir_mode: 750

{{ pillar['pkg_data']['bind']['service'] }}:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/named.conf
      - file: /var/named/data/zones/*.dns
      - file: /etc/named/*conf
      
