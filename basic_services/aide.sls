#
## aide.sls - instala e configura o serviço aide para checkagem do filesystem
# 

{%- if pillar['aide'] | default(False) and pillar['aide']['install'] | default(False) %}
aide:
  pkg.installed
  
# gera o db inicial
{{ pillar['pkg_data']['aide']['aide_db'] }}:
  cmd.run:
    - name: aide --config {{ pillar['pkg_data']['aide']['conf'] }}  --init && mv {{ pillar['pkg_data']['aide']['new_db'] }} {{ pillar['pkg_data']['aide']['aide_db'] }}
    - unless: ls /var/lib/aide/aide.db

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

# mantém o serviço aidechek.service apenas habilitado
aidecheck.service:
  service.enabled

# habilita e inicia o serviço aidecheck.timer
aidecheck.timer:
  service.running:
    - enable: true
    - restart: true

{%- else %}
'=== aide will not be installed ===':
  test.nop

{%- endif %}
