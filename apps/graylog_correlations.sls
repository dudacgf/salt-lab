extract files:
  archive.extracted:
    - name: /tmp
    - source: salt://files/services/graylog/graylog_correlations_service.zip
    - user: graylog
    - group: graylog
    - if_missing: /tmp/correlations_service/install.sh

install service:
  cmd.run:
    - name: /tmp/correlations_service/install.sh
    - cwd: /tmp/correlations_service


