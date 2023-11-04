#
## graylog.sls - installs e setups graylog service
# 

# adds graylog repo
{% if grains['os_family'] == 'Debian' %}
graylog repo:
  pkgrepo.managed:
    - name: deb https://packages.graylog2.org/repo/debian/ stable 5.1
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
    - baseurl: https://packages.graylog2.org/repo/el/stable/5.1/$basearch/
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
  pkg.installed:
    - refresh: True
    - allow_updates: True
  
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
/etc/graylog/ssl/cert.pem:
  file.managed:
    - source: {{ salt.sslfile.cert() }}
    - makedirs: true
    - dir_mode: 770
    - user: graylog
    - group: graylog
    - mode: 660
    - backup: minion

/etc/graylog/ssl/privkey.pem:
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
    - source: salt://files/services/graylog/graylog-server.conf.jinja
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
    - name: /tmp/mongodb_acl_graylog.mql
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

graylog default crypto-policy:
  cmd.run:
    - name: update-crypto-policies --set DEFAULT

graylog configura acl:
  cmd.run:
    - name: 'mongosh -u {{ pillar['mongodb']['admin_user'] }} -p {{ pillar['mongodb']['admin_pw'] }} --quiet < /tmp/mongodb_acl_graylog.mql'
    - require:
      - service: stop graylog now
      - file: /tmp/mongodb_acl_graylog.mql
      - cmd: graylog default crypto-policy

graylog default-sha1 crypto-policy:
  cmd.run:
    - name: update-crypto-policies --set DEFAULT:SHA1

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

{%- if pillar['graylog'] is defined and
       pillar['graylog']['tcp_ports'] is defined %}
graylog tcp_ports:
  cmd.run:
    - name: 'firewall-cmd --permanent --add-port={{ pillar['graylog']['tcp_ports'] }}/tcp'
{%- endif %}

{%- if pillar['graylog'] is defined and
       pillar['graylog']['udp_ports'] is defined %}
graylog udp_ports:
  cmd.run:
    - name: 'firewall-cmd --permanent --add-port={{ pillar['graylog']['udp_ports'] }}/udp'
{%- endif %}

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

# keystore.managed will raise an exception if the certificate exists. Check before adding just to get a pretty output
{%- if not salt.keystore.list(keystore=salt.pillar.get('graylog:cacerts'), passphrase='changeit', alias='ca_root') | default(False) %}
graylog import ca-root chain:
  keystore.managed:
    - name: {{ pillar['graylog']['cacerts'] }}
    - passphrase: changeit
    - entries:
          - alias: ca_root
            certificate: /tmp/chain.pem
    - require:
      - file: graylog tmp ca-root cert
{%- endif %}

# patches sysconfig to point to java keystore
graylog sysconfig patch:
  file.patch:
    - name: /etc/sysconfig/graylog-server
    - source: salt://files/services/graylog/graylog-server.sysconfig.patch
{% endif %}

# will graylog run under an apache proxy? is apache installed?
{%- if pillar['graylog'] is defined and
       pillar['graylog']['apache_proxy'] | default(False) and 
       salt.service.running(pillar['pkg_data']['apache']['service']) | default(False) %}
/etc/httpd/conf.d/graylog_proxy.conf:
  file.managed:
    - source: salt://files/services/graylog/graylog_apache_proxy.conf.jinja
    - template: jinja
    - user: {{ pillar['pkg_data']['apache']['user'] }}
    - group: {{ pillar['pkg_data']['apache']['group'] }}
    - mode: 0644

graylog restart apache service:
  module.run:
    - name: service.reload
    - m_name: {{ pillar['pkg_data']['apache']['service'] }}
    - require:
      - file: /etc/httpd/conf.d/graylog_proxy.conf
    - watch:
      - file: /etc/httpd/conf.d/graylog_proxy.conf

{%- if grains['os_family'] == 'RedHat' and pillar['selinux_mode'] | lower() == 'enforcing' %}
sudo setsebool -P httpd_can_network_connect 1:
  cmd.run
{%- endif %}
{%- endif %} # if apache_proxy

# run the service
graylog-server.service:
  service.running:
    - enable: true
    - restart: true
    - watch:    
      - file: /etc/graylog/server/server.conf

