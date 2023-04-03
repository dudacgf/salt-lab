#
# Adiciona o repositório do graylog
graylog_repo:
  pkgrepo.managed:
    - name: deb https://packages.graylog2.org/repo/debian/ stable 4.1
    - humanname: Graylog repo
    - dist: stable
    - file: /etc/apt/sources.list.d/graylog.list
    - key_url: salt://files/env/GPG-KEY-graylog

