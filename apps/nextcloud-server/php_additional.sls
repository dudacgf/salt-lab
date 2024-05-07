# configuração específica php para o nextcloud
nextcloud extra php modules:
  pkg.installed:
    {%- if grains['os_family'] == 'RedHat' %}
    - pkgs: [ php-bcmath, php-gmp, php-gd, php-process, php-ldap, php-smbclient, php-sodium ]
    {%- else %}
    - pkgs: [ php-bcmath, php-gd, php-ldap, php-smbclient, php-curl ]
    {% endif %}

{%- if grains['os'] == 'Redhat' %}
nextcloud php imagick install:
  cmd.script:
    - source: salt://files/scripts/php_install_imagick.sh
    - unless: php -m | grep imagick

ajusta php-fpm ini:
  file.patch:
    - name: /etc/php-fpm.d/www.conf
    - source: salt://files/services/nextcloud/nextcloud-php_fpm_www_conf.patch
{% endif %}

#
# ajusta php.ini
{% set php_ini = salt.cmd.shell("php --ini 2> /dev/null | grep -i 'loaded configuration file' | sed -- 's/.*: *//'") | 
                 default(pkg_data.php.php_ini) %}
php ini max_execution_time:
  file.replace:
    - name: {{ php_ini }}
    - pattern: max_execution_time = 30
    - repl: max_execution_time = 60
php ini memory_limit:
  file.replace:
    - name: {{ php_ini }}
    - pattern: memory_limit = 128M
    - repl: memory_limit = 512M
php ini date.timezone:
  file.replace:
    - name: {{ php_ini }}
    - pattern: date.timezone =
    - repl: date.timezone = 'America/Sao_Paulo'
