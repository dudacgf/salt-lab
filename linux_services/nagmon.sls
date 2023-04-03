# para minions com role 'nagmon', instala o openconnect para testar VPN dos usuários ao ASA
openconnect_install:
  pkg.installed:
    - pkgs:
      - openconnect

# copia script para check da conexão VPN Anyconnect usada pelos usuários para 
# trabalhar de casa
/usr/lib/nagios/plugins/check_cisco_anyconnect:
  file.managed:
    - source: salt://files/services/nrpe/check_cisco_anyconnect
    - user: root
    - group: root
    - mode: 755
    - backup: minion

