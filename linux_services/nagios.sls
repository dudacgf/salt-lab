# instala nagios, (#pnp4nagios#) e plugins necessários para o nagios
nagiosserver:
  pkg.installed:
    - pkgs:
      - nagios
#      - pnp4nagios
      - nagios-plugins-dhcp
      - nagios-plugins-dig
      - nagios-plugins-disk
      - nagios-plugins-dummy
      - nagios-plugins-tcp
      - nagios-plugins-http
      - nagios-plugins-icmp
      - nagios-plugins-load
      - nagios-plugins-nrpe
      - nagios-plugins-openmanage
      - nagios-plugins-ping
      - nagios-plugins-procs
      - nagios-plugins-smtp
      - nagios-plugins-snmp
      - nagios-plugins-ssh
      - nagios-plugins-swap
      - nagios-plugins-check-updates
      - nagios-plugins-users
      
additionalplugins:
  file.recurse:
    - name: /usr/lib64/nagios/plugins
    - source: salt://files/services/nagios/plugins
    - user: root
    - group: root
    - file_mode: 755

thrukinstall:
  cmd.run:
    - name: rpm -Uvh "https://labs.consol.de/repo/stable/rhel8/x86_64/labs-consol-stable.rhel8.noarch.rpm"
    - unless: ls -l /etc/httpd/conf.d/thruk.conf

