#
## graylog.sls - instala e configura o serviço graylog para análise de logs
# 

# Adiciona o repositório do graylog
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

# o jre é prerequisito para o graylog mas não é instalado como dependência. 
{{ pillar['pkg_data']['jdk']['name'] }}:
  pkg.installed

# manda instalar só o integrations-plugins porque ele instala também o graylog-server
graylog-server: 
  pkg.installed
  
# pacotes necessários para os relatórios:
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

{% if pillar['graylog']['ssl_enable'] | default(False) %}
# chaves de criptografia para tráfego com clientes
/etc/graylog/server/pki/cert.pem:
  file.managed:
    - source: {{ salt.sslfile.cert() }}
    - makedirs: true
    - dir_mode: 770
    - user: root
    - group: graylog
    - mode: 660
    - backup: minion

/etc/graylog/server/pki/privkey.pem:
  file.managed:
    - source: {{ salt.sslfile.privkey() }}
    - makedirs: true
    - dir_mode: 770
    - user: root
    - group: graylog
    - mode: 660
    - backup: minion
{% endif %}

# instala pwgen se necessário
pwgen:
  pkg.installed

# arquivo de configuração do serviço
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
# para o graylog para ajustar usuário
{% if pillar['mongodb']['auth'] | default(False) %}
stop graylog now:
  service.dead:
    - name: graylog-server.service

# adiciona usuário graylog ao mongodb
graylog mongodb access control:
  file.managed:
    - name: /tmp/mongodb_access_control.mql
    - user: mongod
    - group: mongod
    - contents: 
      - 'use graylog;'
      - 'db.createUser('
      - '  {'
      - '    user: "{{ pillar['graylog']['mongodb_user'] }}",'
      - '    pwd: "{{ pillar['graylog']['mongodb_pw'] }}",'
      - '    roles: [ { role: "root", db: "admin" } ]'
      - '  }'
      - ')'
      - 'exit'

graylog configura acl:
  cmd.run:
    - name: 'mongosh -u {{ pillar['mongodb']['admin_user'] }} -p {{ pillar['mongodb']['admin_pw'] }} --quiet < /tmp/mongodb_access_control.mql'
    - require:
      - service: stop graylog now
      - file: /tmp/mongodb_access_control.mql

graylog remove tmp access control:
  file.absent:
    - name: /tmp/mongodb_access_control.mql
    - require:
      - file: graylog mongodb access control
{% endif %}

{% if grains['os_family'] == 'RedHat' %}
#
# abre porta no firewall
graylog firewalld port:
  cmd.run:
    - name: 'firewall-cmd --permanent --add-port=9000/tcp'

graylog firewalld reload:
  cmd.run:
    - name: 'firewall-cmd --reload'

#
# configura selinux
graylog selinux:
  cmd.run:
    - name: semanage port -m -t http_port_t -p tcp 9000

{% endif %}

{% if pillar['elasticsearch']['ssl_enable'] | default(False) %}
# importa chain.pem na java keystore
graylog tmp ca-root cert:
  file.managed:
    - name: /tmp/chain.pem
    - source: {{ salt.sslfile.chain() }}

graylog import ca-root chain:
  keystore.managed:
    - name: /etc/pki/ca-trust/extracted/java/cacerts
    - passphrase: changeit
    - entries:
      - alias: ca_root
        certificate: /tmp/chain.pem
    - require:
      - file: graylog tmp ca-root-chain

# configura sysconfig para apontar para a keystore
graylog sysconfig patch:
  file.patch:
    - name: /etc/sysconfig/graylog-server
    - source: salt://files/services/graylog-server.sysconfig.patch
{% endif %}

#
# ajusta o serviço graylog
graylog-server.service:
  service.running:
    - enable: true
    - restart: true
    - watch:    
      - file: /etc/graylog/server/server.conf

