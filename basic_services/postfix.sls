{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
#
### postfix.sls - instala e configura postfix para uso de relay via office365 (authenticated)
#
### ecgf

{%- if pillar['postfix'] | default(False) and pillar['postfix.install'] | default(False) %}

postfix:
  pkg.installed

install cyrus:
  pkg.installed:
    - pkgs: [ {{ pkg_data.cyrus_sasl.install }} ]

{{ pkg_data.mail.install }}:
  pkg.installed

{% if pillar['postfix']['auth'] | default(False) %}
/etc/postfix/auth_relay:
  file.managed:
    - source: salt://files/services/postfix/auth_relay.jinja
    - template: jinja
    - user: root
    - group: postfix
    - mode: 640

postmap /etc/postfix/auth_relay:
  cmd.run:
    - watch:
      - file: /etc/postfix/auth_relay
{% endif %}

/etc/postfix/generic:
  file.managed:
    - source: salt://files/services/postfix/generic.jinja
    - template: jinja
    - user: root
    - group: postfix
    - mode: 640

postmap /etc/postfix/generic:
  cmd.run:
    - watch:
      - file: /etc/postfix/generic

/etc/postfix/sender_canonical:
  file.managed:
    - source: salt://files/services/postfix/sender_canonical.jinja
    - template: jinja
    - user: root
    - group: postfix
    - mode: 640

postmap /etc/postfix/sender_canonical:
  cmd.run:
    - watch:
      - file: /etc/postfix/sender_canonical

/etc/postfix/main.cf:
  file.managed:
    - source: salt://files/services/postfix/main.cf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644

{% if grains['os_family'] == 'RedHat' and pillar.get('selinux_mode', 'enforcing') == 'enforcing' %}
copia selinux postfix:
  file.managed:
    - name: /tmp/selinux-postlog.pp
    - source: salt://files/selinux/selinux-postlog.pp
    - user: root
    - mode: 640

semodule run:
  cmd.run:
    - name: semodule -X 300 -i /tmp/selinux-postlog.pp
    - require:
      - file: copia selinux postfix

copia systemd unit:
  cmd.run:
    - name: cp /usr/lib/systemd/system/postfix.service /etc/systemd/system/
    - creates: /etc/systemd/system/postfix.service

add touch master pid:
  file.line:
    - name: /etc/systemd/system/postfix.service
    - content: ExecStartPre=-/usr/bin/touch /var/spool/postfix/pid/master.pid
    - after: 'PrivateDevices=true'
    - mode: insert

{% endif %}

postfix.service:
  service.running:
    - enable: true
    - restart: true
    - watch:
      - file: /etc/postfix/*

{%- else %}
'-- postfix will not be installed':
  test.nop

{%- endif %}
