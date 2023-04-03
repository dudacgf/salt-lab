{% if grains['os_family'] == 'Debian' %}
grafana debian gpg key:
  file.managed:
    - name: /usr/share/keyrings/grafana.key
    - source: https://packages.grafana.com/gpg.key
    - skip_verify: True

grafana repo:
  file.managed:
    - name: /etc/apt/sources.list.d/grafana.list
    - contents:
      - "deb [signed-by=/usr/share/keyrings/grafana.key] https://packages.grafana.com/oss/deb stable main"
    - require:
      - file: grafana debian gpg key

{% elif grains['os_family'] == 'RedHat' %}
grafana repo:
  file.managed:
    - name: /etc/yum.repos.d/grafana.repo
    - contents:
      - '[grafana]'
      - 'name=grafana'
      - 'baseurl=https://packages.grafana.com/oss/rpm'
      - 'repo_gpgcheck=1'
      - 'enabled=1'
      - 'gpgcheck=1'
      - 'gpgkey=https://packages.grafana.com/gpg.key'
      - 'sslverify=1'
      - 'sslcacert=/etc/pki/tls/certs/ca-bundle.crt'
{% else %}
grafana failure:
  test.fail_without_changes:
    - name: '*** OS não suportado! ***'
{% endif %}

grafana:
  pkg.installed:
    - refresh: True
    - require: 
      - grafana repo

grafana-server.service:
  service.running:
    - enable: True
    - restart: True
    - require:
      - pkg: grafana

