# aumenta limite de file descriptors (open files)
ulimit -n 65000:
  cmd.run

# aumenta vm.max_map_count=262120
/etc/sysctl.conf:
  file.append:
    - text: 'vm.max_map_count=262120'

sysctl -p:
  cmd.run

# configuração do mongod
/etc/mongod.conf:
  file.managed:
    - source: salt://files/services/mongod.conf.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 644
    - backup: minion

{% if pillar['mongodb']['ssl_enable'] | default(False) %}
mongod copia chain file:
  file.managed:
    - name: /etc/mongodb/chain.pem
    - source: {{ salt.sslfile.chain() }}
    - user: mongod
    - group: mongod
    - makedirs: True

# cria arquivo temporário com cert + privkey em /tmp e depois o copia para o diretório de destino
mongod temp cert file:
  file.managed:
    - name: /tmp/cert+key.pem
    - source: {{ salt.sslfile.fullchain() }}
    - mode: 0644
    - makedirs: True
    - unless: test -f /etc/mongodb/cert+key.pem

mongod apensa privkey file:
  file.append:
    - name: /tmp/cert+key.pem
    - source: {{ salt.sslfile.privkey() }}
    - unless: test -f /etc/mongodb/cert+key.pem

mongod copia cert+key file:
  file.managed:
    - name: /etc/mongodb/cert+key.pem
    - source: /tmp/cert+key.pem
    - user: mongod
    - group: mongod
    - makedirs: True
    - require:
      - file: mongod temp cert file
      - file: mongod apensa privkey file
    - unless: test -f /etc/mongodb/cert+key.pem

mongod remove temp cert file:
  file.absent:
    - name: /tmp/cert+key.pem
    - require:
      - file: mongod copia cert+key file
    - order: last
{%- endif %}

