#
## graylog.sls - installs e setups graylog service
# 

# adds graylog repo
{% if grains['os_family'] == 'Debian' %}
graylog repo:
  pkgrepo.managed:
    - name: deb https://packages.graylog2.org/repo/debian/ stable 5.0
    - humanname: Graylog repo
    - dist: stable
    - file: /etc/apt/sources.list.d/graylog.list
    - key_url: salt://files/env/GPG-KEY-graylog
{% elif grains['os_family'] == 'RedHat' %}
/etc/pki/rpm-gpg/RPM-GPG-KEY-graylog:
  file.managed:
    - source: salt://files/env/GPG-KEY-graylog
    - user: root
    - group: root
    - mode: 644

graylog repo:
  pkgrepo.managed:
    - name: graylog
    - baseurl: https://packages.graylog2.org/repo/el/stable/5.0/$basearch/
    - gpgcheck: 1
    - gpgkey: file:///etc/pki/rpm-gpg/RPM-GPG-KEY-graylog
    - require:
      - file: /etc/pki/rpm-gpg/RPM-GPG-KEY-graylog
{% else %}
graylog failure:
  test.fail_without_changes:
    - text: '*** OS not supported. graylog will not be installed ***'
    - failhard: true
{% endif %}

# o jre is a prerequisite to graylog but is not installed as a dependency 
{{ pillar['pkg_data']['jdk']['name'] }}:
  pkg.installed

# install 
graylog-server: 
  pkg.installed
  
# other packages needed by reports
instala pacotes relatório:
  pkg.installed:
    - pkgs:
    {%- if grains['os_family'] == 'Debian' %}
      - fontconfig
      - fonts-dejavu
    {%- elif grains['os_family'] == 'RedHat' %}
      - fontconfig
      - dejavu-sans-fonts
      - dejavu-serif-fonts
    {%- else %}
      - fontconfig
    {%- endif %}

{% if pillar['graylog'] is defined and 
      pillar['graylog']['ssl_enable'] | default(False) %}
# certificates 
/etc/graylog/server/ssl/cert.pem:
  file.managed:
    - source: {{ salt.sslfile.cert() }}
    - makedirs: true
    - dir_mode: 770
    - user: graylog
    - group: graylog
    - mode: 660
    - backup: minion

/etc/graylog/server/ssl/privkey.pem:
  file.managed:
    - source: {{ salt.sslfile.privkey() }}
    - makedirs: true
    - dir_mode: 770
    - user: graylog
    - group: graylog
    - mode: 660
    - backup: minion
{% endif %}

# install pwgen
pwgen:
  pkg.installed

# configuration file
/etc/graylog/server/server.conf:
  file.managed:
    - source: salt://files/services/graylog-server.conf.jinja
    - template: jinja
    - user: root
    - group: graylog
    - mode: 640
    - backup: minion
    - require: 
      - pkg: pwgen

#
# adds graylog user if mongodb uses authentication
{% if pillar['mongodb'] is defined and 
      pillar['mongodb']['auth'] | default(False) %}
stop graylog now:
  service.dead:
    - name: graylog-server.service

graylog mongodb access control:
  file.managed:
    - name: /tmp/mongodb_access_control.mql
    - user: mongod
    - group: mongod
    - contents: |
         use graylog;
         db.createUser(
           {
             user: "{{ pillar['graylog']['mongodb_user'] }}",
             pwd: "{{ pillar['graylog']['mongodb_pw'] }}",
             roles: [ { role: "root", db: "admin" } ]
           }
         )
         exit

graylog configura acl:
  cmd.run:
    - name: 'mongosh -u {{ pillar['mongodb']['admin_user'] }} -p {{ pillar['mongodb']['admin_pw'] }} --quiet < /tmp/mongodb_access_control.mql'
    - require:
      - service: stop graylog now
      - file: /tmp/mongodb_access_control.mql

#graylog remove tmp access control:
#  file.absent:
#    - name: /tmp/mongodb_access_control.mql
#    - order: last
#    - require:
#      - cmd: graylog configura acl
{% endif %}

{% if grains['os_family'] == 'RedHat' %}
#
# opens firewall 
graylog firewalld port:
  cmd.run:
    - name: 'firewall-cmd --permanent --add-port=9000/tcp'

graylog firewalld reload:
  cmd.run:
    - name: 'firewall-cmd --reload'

#
# selinux
graylog selinux:
  cmd.run:
    - name: semanage port -m -t http_port_t -p tcp 9000

{% endif %}

# if elasticsearch uses ssl/tls imports chain.pem into java keystore
{% if pillar['elasticsearch'] is defined and
      pillar['elasticsearch']['ssl_enable'] | default(False) %}
graylog tmp ca-root cert:
  file.managed:
    - name: /tmp/chain.pem
    - source: {{ salt.sslfile.chain() }}
    - mode: 440

graylog import ca-root chain:
  keystore.managed:
    - name: /etc/pki/ca-trust/extracted/java/cacerts
    - passphrase: changeit
    - entries:
          - alias: ca_root
            certificate: /tmp/chain.pem
    - require:
      - file: graylog tmp ca-root cert

# patches sysconfig to point to java keystore
graylog sysconfig patch:
  file.patch:
    - name: /etc/sysconfig/graylog-server
    - source: salt://files/services/graylog-server.sysconfig.patch
{% endif %}

# run the service
graylog-server.service:
  service.running:
    - enable: true
    - restart: true
    - watch:    
      - file: /etc/graylog/server/server.conf

