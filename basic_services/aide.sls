#
## aide.sls - instala e configura o serviço aide para checkagem do filesystem
# 

{%- if (pillar['aide'] | default(False) and pillar['aide']['install'] | default(False)) 
        or pillar['cis'] | default(False) == 'enforced' %}
aide:
  pkg.installed
  
# gera o db inicial
{{ pillar.pkg_data.aide.aide_db }}:
  cmd.run:
    - name: aideinit -y -f

# Ajusta os serviços do aide

# cria os dois arquivos do systemd
/etc/systemd/system/aidecheck.service:
  file.managed:
    - source: salt://files/services/aidecheck.service.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - backup: minion

/etc/systemd/system/aidecheck.timer:
  file.managed:
    - source: salt://files/services/aidecheck.timer
    - user: root
    - group: root
    - mode: 644
    - backup: minion

reload system daemon:
  cmd.wait:
    - name: systemctl daemon-reload
    - watch:
      - file: /etc/systemd/system/aidecheck.timer
      - file: /etc/systemd/system/aidecheck.service

# CIS 4.1.4.11 Ensure cryptographic mechanisms are used to protect 
#              the integrity of audit tools
{% set after = salt.grains.filter_by({'Debian': 'LinkedLog = Log-n', 'RedHat': '/etc    PERMS'}) %}
{{ pillar.pkg_data.aide.conf }}:
  file.replace:
    - pattern: '^({{ after }})$'
    - repl: |
          \1

          # CIS 4.1.4.11 Ensure cryptographic mechanisms are used to protect the integrity of audit tools
          /usr/sbin/auditctl p+i+n+u+g+s+b+acl+xattrs+sha512
          /usr/sbin/auditd p+i+n+u+g+s+b+acl+xattrs+sha512
          /usr/sbin/ausearch p+i+n+u+g+s+b+acl+xattrs+sha512
          /usr/sbin/aureport p+i+n+u+g+s+b+acl+xattrs+sha512
          /usr/sbin/autrace p+i+n+u+g+s+b+acl+xattrs+sha512
          /usr/sbin/augenrules p+i+n+u+g+s+b+acl+xattrs+sha512
          /usr/sbin/rsyslogd p+i+n+u+g+s+b+acl+xattrs+sha512
    - unless: 'grep /sbin/auditctl {{ pillar.pkg_data.aide.conf }}'

# mantém o serviço aidechek.service apenas habilitado
aidecheck.service:
  service.enabled

# habilita e inicia o serviço aidecheck.timer
aidecheck.timer:
  service.running:
    - enable: true
    - restart: true
    - watch:
      - file: {{ pillar.pkg_data.aide.conf }}

{%- else %}
'-- aide will not be installed':
  test.nop

{%- endif %}
