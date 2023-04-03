#
## filebeat.sls - instala e configura o serviço filebeat para envio de logs para o graylog
# 
filebeat:
  pkg.installed
  
{%- set hostname = grains['id'].split('.')[0] %}
# arquivos de configuração do serviço
/etc/filebeat/modules/auditd.yml:
  cmd.run:
    - name: filebeat modules enable auditd
    - creates: /etc/filebeat/modules.d/auditd.yml

/etc/filebeat/modules/system.yml:
  cmd.run:
    - name: filebeat modules enable system
    - creates: /etc/filebeat/modules.d/system.yml

{%- if hostname == 'netflow01' %}
/etc/filebeat/modules/netflow.yml:
  cmd.run:
    - name: filebeat modules enable netflow
    - creates: /etc/filebeat/modules.d/netflow.yml

/etc/filebeat/filebeat.yml:
  file.managed:
    - source: salt://files/services/filebeat.yml.netflow
    - user: root
    - group: root
    - mode: 600
    - backup: minion
{% else %}
/etc/filebeat/filebeat.yml:
  file.managed:
    - source: salt://files/services/filebeat.yml.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 600
    - backup: minion
{% endif %}

# copia as chaves para comunicação com o graylog
/etc/filebeat/files/pki/CA_Icatu.crt:
  file.managed:
    - source: salt://files/pki/CA_Icatu.crt
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - backup: minion

/etc/filebeat/files/pki/beat.client.icatu.rede.pem:
  file.managed:
    - source: salt://files/pki/beatclient/beat.client.icatu.rede.pem
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - backup: minion

/etc/filebeat/files/pki/beat.client.icatu.rede.key:
  file.managed:
    - source: salt://files/pki/beatclient/beat.client.icatu.rede.key
    - user: root
    - group: root
    - mode: 644
    - makedirs: true
    - dir_mode: 755
    - backup: minion

#
# ajusta o serviço filebeat
filebeat.service:
  service.running:
    - enable: true
    - restart: true
    - watch:
      - file: /etc/filebeat/filebeat.yml

