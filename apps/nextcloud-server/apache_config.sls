{% if grains['os_family'] == 'Debian' %}
  {% set ssl_file = '/etc/apache2/sites-available/default-ssl.conf' %}
{% else %}
  {% set ssl_file = '/etc/httpd/conf.d/ssl.conf' %}
{% endif %}
# configuração apache para o nextcloud
nextcloud copia apache conf:
  file.replace:
    - name: {{ ssl_file }}
    - pattern: 'DocumentRoot /var/www/html'
    - repl: |
        Header always set Strict-Transport-Security "max-age=15552000; includeSubDomains"
                DocumentRoot /var/www/nextcloud

                <location />
                    <LimitExcept GET POST HEAD PUT PROPFIND>
                        deny from all
                    </LimitExcept>
                </location>

                <Directory /var/www/nextcloud/>
                  Require all granted
                  AllowOverride All
                  Options FollowSymLinks MultiViews

                  <IfModule mod_dav.c>
                    Dav off
                  </IfModule>
                </Directory>

nextcloud reload apache:
  service.running:
    - name: {{ pkg_data.apache.service }}
    - restart: True
    - watch:
      - file: nextcloud copia apache conf

