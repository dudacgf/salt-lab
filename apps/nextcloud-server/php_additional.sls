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

ajusta php ini:
  file.patch:
    - name: {{ pillar['pkg_data']['php']['php_ini'] }}
    - source: salt://files/services/nextcloud/nextcloud_php_ini.patch

