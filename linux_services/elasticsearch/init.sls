{% include "linux_services/elasticsearch/install.sls" %}
{% include "linux_services/elasticsearch/configure.sls" %}

#
# restarts the service 
final elasticsearch service.restart:
  module.run:
    - name: service.restart
    - m_name: elasticsearch.service

#
# finalmente, checa a instalação
#
checa elasticsearch:
  cmd.script:
    - source: salt://files/checks/check_elasticsearch.sh.jinja
    - template: jinja
    - require:
      - module: final elasticsearch service.restart

