#!jinja|yaml
## config_ssl.sls - configura uso de certificados e protocolo ssl no apache 
#                   ao chegar aqui, certificado, chave e chain já foram criados e 
#                   disponibilizados em ssl/cert.pem, ssl/privkey.pem e ssl/chain.pem
#                   abaixo do diretório apache
#

{% if not pillar.get('apache_ssl', False) %}
nada a fazer:
  test.nop:
    - name: '*** servidor não usa https. nada a fazer'
   
{% else %}
   
# copia certificados et all
copy certificate:
  file.managed:
    - name: {{ pillar['pkg_data']['apache']['etc_dir'] }}/ssl/cert.pem
    - source: {{ salt.sslfile.cert() }}
    - user: {{ pillar['pkg_data']['apache']['user'] }}
    - group: {{ pillar['pkg_data']['apache']['group'] }}
    - mode: 640
    - makedirs: True
    - dir_mode: 750
   
copy privkey:
  file.managed:
    - name: {{ pillar['pkg_data']['apache']['etc_dir'] }}/ssl/privkey.pem
    - source: {{ salt.sslfile.privkey() }}
    - user: {{ pillar['pkg_data']['apache']['user'] }}
    - group: {{ pillar['pkg_data']['apache']['group'] }}
    - mode: 640
    - makedirs: True
    - dir_mode: 750
   
copy chain:
  file.managed:
    - name: {{ pillar['pkg_data']['apache']['etc_dir'] }}/ssl/chain.pem
    - source: {{ salt.sslfile.chain() }}
    - user: {{ pillar['pkg_data']['apache']['user'] }}
    - group: {{ pillar['pkg_data']['apache']['group'] }}
    - mode: 640
    - makedirs: True
    - dir_mode: 750
   
# 
## instala/habilita módulo ssl e atualiza configuração ssl do servidor
{% if grains['os_family'] == 'Debian' %}
a2enmod ssl:
  cmd.run
   
ssl configuration:
  file.managed:
    - name: {{ pillar['pkg_data']['apache']['etc_dir'] }}/sites-available/default-ssl.conf
    - source: salt://files/services/apache/ssl-debian.conf.jinja
    - template: jinja
    - user: {{ pillar['pkg_data']['apache']['user'] }}
    - group: {{ pillar['pkg_data']['apache']['group'] }}
    - mode: 640
   
a2ensite default-ssl:
  cmd.run:
    - require:
      - file: ssl configuration
   
{% elif grains['os_family'] == 'RedHat' %}

mod_ssl:
  pkg.installed
   
ssl configuration:
  file.managed:
    - name: {{ pillar['pkg_data']['apache']['etc_dir'] }}/conf.d/ssl.conf
    - source: salt://files/services/apache/ssl-redhat.conf.jinja
    - template: jinja
    - user: {{ pillar['pkg_data']['apache']['user'] }}
    - group: {{ pillar['pkg_data']['apache']['group'] }}
    - mode: 640
  
{% endif %}
   
ssl restart apache:
  cmd.run:
    - name: systemctl restart {{ pillar['pkg_data']['apache']['service'] }}
    - require:
      - file: ssl configuration
   
flag_apache_ssl_configured:
  grains.present:
    - value: True
    - require:
      - cmd: ssl restart apache

{% endif %} # if apache_ssl

