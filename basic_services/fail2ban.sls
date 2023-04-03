#
## instala e configura o fail2ban. inicialmente, apenas para ssh

fail2ban:
  pkg.installed

/etc/fail2ban/jail.local:
  file.append:
    - source: salt://files/services/fail2ban.jail.local

fail2ban.service:
  service.running:
    - enable: true
    - reload: true
    - watch:
      - file: /etc/fail2ban/jail.local
