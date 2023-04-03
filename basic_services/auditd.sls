#
## auditd.sls - instala e configura o serviço auditd para auditoria do servidor
# 
{{ pillar['pkg_data']['audit']['name'] }}:
  pkg.installed
  
# regras de auditoria
##
/etc/audit/rules.d/audit.rules:
  file.managed:
    - source: salt://files/services/audit.rules
    - user: root
    - group: root
    - mode: 600
    - backup: minion

# ajusta o serviço auditd

auditd.enabled:
  service.enabled:
    - name: auditd.service

restart auditd:
  cmd.run:
    - name: 'service auditd restart'
    - watch: 
      - file: /etc/audit/rules.d/audit.rules

