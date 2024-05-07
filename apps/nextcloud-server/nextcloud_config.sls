# configura config.php, apps e alguns settings de ldap para login
{% if not grains['flag_nextcloud_config_loaded'] | default(False) %}
nextcloud copia config php:
  file.managed:
    - name: /tmp/config.json
    - source: salt://files/services/nextcloud/config_import.json.jinja
    - template: jinja
    - user: {{ pkg_data.apache.user }}
    - group: {{ pkg_data.apache.group }}
    - mode: 640

nextcloud import config:
  cmd.run:
    - name: php /var/www/nextcloud/occ config:import /tmp/config.json
    - runas: {{ pkg_data.apache.user }}
    - require:
      - file: nextcloud copia config php

nextcloud habilita apps:
  cmd.run:
    - name: php /var/www/nextcloud/occ app:enable files_pdfviewer user_ldap admin_audit files_external
    - runas: {{ pkg_data.apache.user }}

nextcloud desabilita first run wizard:
  cmd.run:
    - name: php /var/www/nextcloud/occ app:disable firstrunwizard
    - runas: {{ pkg_data.apache.user }}

nextcloud copia files_external config:
  file.managed:
    - name: /tmp/nextcloud_fe_cs.json
    - source: salt://files/services/nextcloud/nextcloud-files-external-conferencia-suporte.json
    - require:
      - cmd: nextcloud habilita apps

nextcloud importa files_external config:
  cmd.run:
    - name: php /var/www/nextcloud/occ files_external:import /tmp/nextcloud_fe_cs.json
    - runas: {{ pkg_data.apache.user }}
    - require:
      - file: nextcloud copia files_external config

nextcloud instala fulltextsearch:
  cmd.run:
    - name: php /var/www/nextcloud/occ app:install -f --allow-unstable -q -n fulltextsearch | echo
    - runas: {{ pkg_data.apache.user }}

nextcloud instala files_fulltextsearch:
  cmd.run:
    - name: php /var/www/nextcloud/occ app:install -f --allow-unstable -q -n files_fulltextsearch | echo
    - runas: {{ pkg_data.apache.user }}

nextcloud instala fulltextsearch_elasticsearch:
  cmd.run:
    - name: php /var/www/nextcloud/occ app:install -f --allow-unstable -q -n fulltextsearch_elasticsearch | echo
    - runas: {{ pkg_data.apache.user }}

nextcloud habilita fulltextsearch:
  cmd.run:
    - name: php /var/www/nextcloud/occ app:enable files_fulltextsearch fulltextsearch fulltextsearch_elasticsearch
    - runas: {{ pkg_data.apache.user }}
    - require:
      - cmd: nextcloud instala fulltextsearch
      - cmd: nextcloud instala fulltextsearch_elasticsearch
      - cmd: nextcloud instala files_fulltextsearch

nextcloud elastic ingest-attachment install:
  cmd.run:
    - name: /usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-attachment
    - runas: elasticsearch

{% set ldap_configs = pillar['nextcloud']['ldap_config'] | default({}) %}
{% for config_ID in ldap_configs %} # (não tenho como definir o nome da nova config. ele cria como s01 s02 etc e é como está no pillar)
nextcloud cria empty ldap config {{ config_ID }}:
  cmd.run:
    - name: php /var/www/nextcloud/occ ldap:create-empty-config
    - runas: {{ pkg_data.apache.user }}
    - require:
      - cmd: nextcloud habilita apps

   {% set config_list = pillar['nextcloud']['ldap_config'][config_ID] | default({}) %}
   {% for config_name in config_list %}
nextcloud set ldap {{ config_name }}:
  cmd.run:
    - name: php /var/www/nextcloud/occ ldap:set-config {{ config_ID }} {{ config_name }} '{{ pillar['nextcloud']['ldap_config'][config_ID][config_name] }}'
    - runas: {{ pkg_data.apache.user }}
    - require:
      - cmd: nextcloud cria empty ldap config {{ config_ID }}
   {% endfor %}
{% endfor %}

flag_nextcloud_config_loaded:
  grains.present:
    - value: True

{% endif %} # flag_nextcloud_config_loaded

