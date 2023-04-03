{% if grains['os_family'] == 'Debian' %}
  {% set ssl_file = '/etc/apache2/sites-available/default-ssl.conf' %}
{% else %}
  {% set ssl_file = '/etc/httpd/conf.d/ssl.conf' %}
{% endif %}
# configuração apache para o nextcloud
nextcloud copia apache conf:
  file.patch:
    - name: {{ ssl_file }}
    - source: salt://files/services/apache/nextcloud-server-ssl-conf.patch.jinja
    - template: jinja

nextcloud reload apache:
  service.running:
    - name: {{ pillar['pkg_data']['apache']['service'] }}
    - restart: True
    - watch:
      - file: nextcloud copia apache conf

