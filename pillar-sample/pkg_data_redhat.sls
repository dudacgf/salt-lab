pkg_data:
  console-data:
    install: False
  
  langpack:
    name: langpacks-pt_BR
  #
  nrpe:
    name: nrpe
    service: nrpe.service
    plugins_dir: /usr/lib64/nagios/plugins/
    install_plugins: 'nagios-plugins-disk, nagios-plugins-dns, nagios-plugins-http, nagios-plugins-swap, nagios-plugins-users, nagios-plugins-procs, nagios-plugins-check-updates, nagios-plugins-nrpe, nagios-plugins-load'
  #
  apache: 
    name: httpd
    service: httpd.service
    confd_dir: /etc/httpd/conf.d
    etc_dir: /etc/httpd
    user: apache
    group: apache
    access_log: access_log
    error_log: error_log
    log_dir: /var/log/httpd
  #
  bind:
    name: bind
    service: named.service
  #
  bindlibs:
    name: bind-libs
  #
  bindutils:
    name: bind-utils
  #
  cyrus_sasl:
    install: 'cyrus-sasl, cyrus-sasl-lib, cyrus-sasl-plain'
  #
  vim:
    name: vim-enhanced
  #
  sshd:
    name: openssh-server
    service: sshd.service
  #
  audit:
    name: audit
  #
  aide:
    conf: /etc/aide.conf
    new_db: /var/lib/aide/aide.db.new.gz
    aide_db: /var/lib/aide/aide.db.gz
    aide_cmd: /usr/bin/aide
  #
  chrony:
    conf: /etc/chrony.conf
    service: chronyd.service
  #
  snmpd:
    name: net-snmp
  #
  php:
   remi_release: https://rpms.remirepo.net/enterprise/remi-release-{{ grains['osmajorrelease'] }}.rpm
   zip: php-pecl-zip
   imagick: php-pecl-imagick-im6
   mysql: php-mysqlnd
   php_ini: /etc/php.ini
  #
  mariadb:
    server_conf: /etc/my.cnf.d/mariadb-server.cnf
  #
  syslog-ng:
    name: syslog-ng
    mod_http: syslog-ng-http
  #
  python:
    dnspython: python3-dns
  #
  mail:
    {%- if grains['osmajorrelease'] <= 8 %}
    install: mailx
    {%- else %}
    install: s-nail
    {%- endif %}
  #
  dhcp-server:
    name: dhcp-server
    service: dhcpd.service
  jdk:
    name: java-17-openjdk
  #
  networkmanager:
    name: NetworkManager
  #
  duo:
    name: duo_unix
  #
  zabbix:
    name: zabbix-agent2
    conffile: /etc/zabbix/zabbix_agent2.conf
  # 
  salt-pycurl-requirements: 'gcc, openssl-devel, libcurl-devel'
  #
  guestfs-tools:
    name: libguestfs-tools-c
