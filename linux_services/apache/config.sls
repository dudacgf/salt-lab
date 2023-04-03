## config.sls - configura apache (hardening, modules etc)
#

#
# relê todos os grains para pegar flag setado nessa rodada
reload grains before config:
  test.nop:
    - reload_grains: True

#
## hardening básico
hardening:
  file.managed:
    - name: {{ pillar['pkg_data']['apache']['confd_dir'] }}/hardening.conf
    - source: salt://files/services/apache/hardening.conf.jinja
    - template: jinja
    - user: {{ pillar['pkg_data']['apache']['user'] }}
    - group: {{ pillar['pkg_data']['apache']['group'] }}
    - mode: 644

{% if grains['os_family'] == 'Debian' %}
# habilita configuração de hardening
habilita modulos:
  cmd.run:
    - name: a2enmod headers proxy proxy_http rewrite

a2enconf hardening:
  cmd.run:
    - require:
      - cmd: habilita modulos

{% endif %}

{% if grains['os_family'] == 'RedHat' %}
# habilita portas http/https para o apache
public:
  firewalld.present:
    - services: [ 'http', 'https' ]

{% endif %}

#
## apaga 
/var/www/html/index.php:
  file.absent

/var/www/html/index.html:
  file.managed:
    - source: salt://files/services/apache/index.html

#
## reinicia o serviço se houver alterações no diretório de configuração
hardening restart:
  service.running:
    - name:  '{{ pillar['pkg_data']['apache']['service'] }}'
    - enable: true
    - reload: true
    - watch:
      - file: hardening
    - require:
      - file: hardening

