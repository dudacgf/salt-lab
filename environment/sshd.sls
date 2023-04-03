#
## sshd.sls - configura segurança do serviço sshd
# 

{{ pillar['pkg_data']['sshd']['name'] }}:
  pkg.installed
  
#
# arquivo de configuração do serviço
/etc/ssh/sshd_config:
  file.managed:
    - source: salt://files/services/sshd_config.jinja
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - backup: minion

#
# arquivo que determina quais modulos serão aceitos (cifra baixa <3072 cortados)
/etc/ssh/moduli:
  file.managed:
    - source: salt://files/services/sshd_moduli
    - user: root
    - group: root
    - mode: 644
    - backup: minion

#
## regera ssh-hostkeys. apenas na primeira execução (flag: ssh_hostkeys_new)
#
{% if not grains.get('flag_ssh_hostkeys_new', False) %}

# remove as chaves anteriores
"rm -f /etc/ssh/ssh_host_*":
  cmd.run

# gera as novas
ssh-keygen -A:
  cmd.run

# não quero as dsa
'/etc/ssh/ssh_host_dsa*':
  file.absent 

{% if grains['os_family'] == 'RedHat' %}
# precisa restaurar contexto selinux 
'restorecon /etc/ssh/ssh_host_*':
  cmd.run
{% endif %}

# restarta serviço sshd pra garantir que vai passar a usar as novas chaves
systemctl restart {{ pillar['pkg_data']['sshd']['service'] }}:
  cmd.run

# marca como já executado para não repetir no próximo highstate
flag_ssh_hostkeys_new:
  grains.present:
    - value: True

{% endif %} # flag_ssh_hostkeys_new

# 
# ajusta o serviço sshd
{{ pillar['pkg_data']['sshd']['service'] }}: 
  service.running:
    - enable: true
    - restart: true
    - watch:
      - file: /etc/ssh/sshd_config
      - file: /etc/ssh/moduli
