{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
#
## sshd.sls - configura segurança do serviço sshd
# 

{% if pillar['sshd_install'] | default(True) %}

{{ pkg_data.sshd.name }}:
  pkg.installed
  
#
## regera ssh-hostkeys. apenas na primeira execução (flag: ssh_hostkeys_new)
#
{% if not grains.get('flag_ssh_hostkeys_new', False) %}

# remove as chaves anteriores
"rm -f /etc/ssh/ssh_host_*":
  cmd.run

# gera as novas
/etc/ssh/ssh_host_ecdsa_key:
  cmd.run:
    - name: 'ssh-keygen -A'

# não quero as *dsa*
'rm -f /etc/ssh/ssh_host_dsa*': cmd.run
'rm -f /etc/ssh/ssh_host_ecdsa*': cmd.run

## CIS 5.2.2 Ensure permissions on SSH private host key files are configured
"find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec chmod 0600 {} \\;": cmd.run
"find /etc/ssh -xdev -type f -name 'ssh_host_*_key' -exec chown root:root {} \\;": cmd.run

## CIS 5.2.3 Ensure permissions on SSH public host key files are configured 
"find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' -exec chmod 0644 {} \\;": cmd.run
"find /etc/ssh -xdev -type f -name 'ssh_host_*_key.pub' -exec chown root:root {} \\;": cmd.run


{% if grains['os_family'] == 'RedHat' %}
# ssh_host_*_key must be group owned by ssh_keys
'chgrp ssh_keys /etc/ssh/ssh_host_*_key': cmd.run

# precisa restaurar contexto selinux 
'restorecon /etc/ssh/ssh_host_*': cmd.run

/etc/ssh/sshd_config.d/50-redhat.conf:
  file.replace:
    - pattern: '^X11Forwarding yes$'
    - repl: 'X11Forwarding no'
{% endif %}


# restarta serviço sshd pra garantir que vai passar a usar as novas chaves
systemctl restart {{ pkg_data.sshd.service }}:
  cmd.run:
    - watch:
      - /etc/ssh/ssh_host_ecdsa_key


# marca como já executado para não repetir no próximo highstate
flag_ssh_hostkeys_new:
  grains.present:
    - value: True
    - require:
      - cmd: ssh-keygen -A

{% endif %} # flag_ssh_hostkeys_new

#
## CIS 5.2.1 Ensure permissions on /etc/ssh/sshd_config are configured (0600)
/etc/ssh/sshd_config:
  file.managed:
    - source: salt://files/services/ssh/sshd_config.jinja
    - user: root
    - group: root
    - mode: 0600
    - template: jinja

/etc/ssh/sshd_config.d/99_sshd_users.conf:
  file.managed:
    - source: salt://files/services/ssh/99_sshd_users
    - user: root
    - group: root
    - mode: 0600
    - template: jinja

#
# arquivo que determina quais modulos serão aceitos (cifra baixa <3072 cortados)
/etc/ssh/moduli:
  file.managed:
    - source: salt://files/services/ssh/sshd_moduli
    - user: root
    - group: root
    - mode: 644
    - backup: minion

# 
# ajusta o serviço sshd
{{ pkg_data.sshd.service }}: 
  service.running:
    - enable: true
    - restart: true
    - watch:
      - file: /etc/ssh/sshd_config
      - file: /etc/ssh/moduli
      - file: /etc/ssh/sshd_config.d/99_sshd_users.conf

{% else %}
{{ pkg_data.sshd.name }}: pkg.removed

'-- openssh-server removed':
  test.nop:
    - onchanges:
      - pkg: {{ pkg_data.sshd.name }}
{% endif %}


