pkg_data:
  console-data:
    install: True
    name: console-data
  #
  langpack:
    name: language-pack-pt
  #
  apache:
    name: apache2
    service: apache2.service
    user: www-data
    group: www-data
    confd_dir: /etc/apache2/conf-available
    etc_dir: /etc/apache2
    home_dir: /var/www
    access_log: access.log
    error_log: error.log
    log_dir: '${APACHE_LOG_DIR}'
  #
  nrpe:
    name: nagios-nrpe-server
    service: nagios-nrpe-server.service
    plugins_dir: /usr/lib/nagios/plugins/
    install_plugins: 'nagios-plugins-contrib'
  #
  bind:
    name: bind9
    service: named.service
  #
  bindlibs:
    name: bind9-libs
  #
  bindutils:
  {%- if grains['os'] == 'Debian' %}
    name: bind9utils
  {%- else %}
    name: bind9-utils
  {%- endif %}
  #
  cyrus_sasl:
    install: 'libsasl2-2, libsasl2-modules'
  #
  vim:
    name: vim
  #
  sshd:
    name: openssh-server
    service: ssh.service
  #
  audit:
    name: auditd
  #
  aide:
    conf: /etc/aide/aide.conf
    new_db: /var/lib/aide/aide.db.new
    aide_db: /var/lib/aide/aide.db
    aide_cmd: /usr/bin/aide.wrapper
  #
  chrony:
    conf: /etc/chrony/chrony.conf
    service: chrony.service
  #
  snmpd:
    name: snmpd
  #
  php:
    remi_release: none
    zip: php-zip
    imagick: php-imagick
    mysql: php-mysql
    confd_dir: /etc/apache2/conf-available
    php_ini: /etc/php/8.1/apache2/php.ini
  #
  mariadb:
    server_conf: /etc/mysql/mariadb.conf.d/50-server.cnf
  #
  syslog-ng:
    name: syslog-ng
    mod_http: syslog-ng-mod-http
  #
  python:
    dnspython: python3-dnspython
  #
  mail:
    install: mailutils
  #
  nomachine:
    {%- if grains['cpuarch'] == 'aarch64' %}
      name: https://download.nomachine.com/download/8.1/Arm/nomachine_8.1.2_1_arm64.deb
    {%- else %}
      name: https://download.nomachine.com/download/8.1/Linux/nomachine_8.1.2_1_amd64.deb
    {%- endif %}
  dhcp-server:
    name: isc-dhcp-server
    service: isc-dhcp-server.service
  jdk:
    name: openjdk-17-jre
