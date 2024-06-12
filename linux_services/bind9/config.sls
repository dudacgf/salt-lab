{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}

/etc/named.conf:
  file.managed:
    - source: salt://files/services/bind9/named.conf.jinja
    - template: jinja
    - user: root
    - group: {{ pkg_data.named.group }}
    - mode: 640

{{ pkg_data.named.service }}:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/named.conf
      
# CIS BIND 9 #2.1 - Disable named service user
usermod -p '!' {{ pkg_data.named.user }} :
  cmd.run:
    - unless: eval [ `passwd -S {{ pkg_data.named.user }} | grep -E '^{{ pkg_data.named.user }} L' -c` -gt 0 ]

chage -d $(date +%C%y-%m-%d -d "-30 days") {{ pkg_data.named.user }}:
  cmd.run
