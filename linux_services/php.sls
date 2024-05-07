{%- import_yaml "maps/pkg_data/by_os_family.yaml" as pkg_data %}
{%- set pkg_data = salt.grains.filter_by(pkg_data) -%}
##
# php.sls - instala http, php e extensões necessárias para rodar wordpress
#
# (c) ecgf - Jun/2021
# 
##

#
# instala o php 
# 
install_php:
  pkg.installed:
    - pkgs:
      - php 
      - php-gd
      - {{ pkg_data.php.mysql }}
      - php-mbstring 
      - php-xml 
      - {{ pkg_data.php.zip }}
      - php-bcmath
      - php-intl
      - {{ pkg_data.php.imagick }}

/var/www/html/x.php:
  file.managed:
    - source: salt://files/services/apache/x.php

systemctl restart {{ pkg_data.apache.service }}:
  cmd.run:
    - watch:
      - file: /var/www/html/x.php
