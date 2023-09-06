#
# 
##
#
## php.sls - instala http, php e extensões necessárias para rodar wordpress
#
## (c) ecgf - Jun/2021
# 
##

#
# em sistemas baseados em redhat, preciso dos repositórios do remi
{% if grains['os_family'] == 'RedHat' %}
{% if not grains.get('flag_remi_installed', False) %} 

instala remi:
  cmd.run:
    - name: dnf install dnf-utils {{ pillar['pkg_data']['php']['remi_release'] }} -y

reset php:
  cmd.run:
    - name: dnf module reset php -y
    - require:
      - cmd: instala remi

enable_remi_81:
  cmd.run:
    - name: dnf module enable php\:remi-8.1 -y
    - require:
      - cmd: reset php

flag_remi_installed:
  grains.present:
    - value: True
    - require:
      - cmd: enable_remi_81

{% endif %}
{% elif grains['os'] == 'Debian' and grains['osmajorrelease'] < 12 %}
/etc/apt/trusted.gpg.d/php.gpg:
  file.managed:
    - source: https://packages.sury.org/php/apt.gpg
    - skip_verify: True
    - makedirs: True

repo php-sury:
  pkgrepo.managed:
    - name: "deb [signed-by=/etc/apt/trusted.gpg.d/php-sury.gpg arch=amd64] https://packages.sury.org/php/ bullseye main"
    - baseurl: "https://packages.sury.org/php"
    - humanname: Debian - PHP Sury
    - file: /etc/apt/sources.list.d/php-sury.list
    - key_url: https://packages.sury.org/php/apt.gpg
    - aptkey: False
{% endif %}

#
# instala o php 
# 
install_php:
  pkg.installed:
    - pkgs:
      - php 
      - php-gd
      - {{ pillar['pkg_data']['php']['mysql'] }}
      - php-mbstring 
      - php-xml 
      - {{ pillar['pkg_data']['php']['zip'] }}
      - php-bcmath
      - php-intl
      - {{ pillar['pkg_data']['php']['imagick'] }}

/var/www/html/x.php:
  file.managed:
    - source: salt://files/services/apache/x.php

systemctl restart {{ pillar['pkg_data']['apache']['service'] }}:
  cmd.run:
    - watch:
      - file: /var/www/html/x.php
