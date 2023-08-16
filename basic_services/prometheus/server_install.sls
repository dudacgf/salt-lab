{% if grains['os_family'] == 'RedHat' %}
#
# Adiciona o repositório do prometheus para servidores redhat

# força aceitação de sha-1 signed keys
permit sha1 keys:
  cmd.run:
    - name: update-crypto-policies --set LEGACY

prometheus repo:
  pkgrepo.managed:
   - name: prometheus-rpm_release
   - baseurl: https://packagecloud.io/prometheus-rpm/release/el/9/$basearch
   - gpgcheck: 0
   - gpgkey: https://packagecloud.io/prometheus-rpm/release/gpgkey
   - repo_gpgcheck: 0

{% elif grains['os_family'] == 'Debian' %}
prometheus repo:
  test.show_notification:
    - text: '*** Debian e Ubuntu já tem prometheus na base ***'

{% else %}
prometheus failure:
  test.fail_without_changes:
    - name: '*** OS não suportado! ***'
    - failhard: True

{% endif %}

instala prometheus:
  pkg.installed:
    - name: prometheus2
    - require:
      - prometheus repo

