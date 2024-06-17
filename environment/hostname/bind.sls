{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
{%- import_yaml "maps/services/bind9/" + pillar.bind_map | default('bind9') + ".yaml" as b9 %}

# register a minion in bind9 dns server
python3-{{pkg_data.python3.dnspython}}:
  pkg.installed

python3-{{pkg_data.python3.yaml}}:
  pkg.installed

{% set domain = pillar[pillar.location + '_domain'] %}
/root/.bind/credentials:
  file.managed:
    - makedirs: True
    - user: root
    - group: root
    - mode: 400
    - contents: |
        {{ domain }}:
           algorithm: {{ b9.zones[domain]['update_key']['algorithm'] }}
           name: {{ b9.zones[domain]['update_key']['name'] }}
           secret: {{ b9.zones[domain]['update_key']['secret'] }}

/usr/local/bin/bind_ddns.py:
  file.managed:
    - source: salt://files/scripts/bind_ddns.py
    - user: root
    - group: root
    - mode: 0755

register host:
  cmd.run:
    - name: /usr/local/bin/bind_ddns.py -k /root/.bind/credentials -t A -z {{domain}} -d {{grains.id.split('.')[0]}} -i {{grains.ipv4 | difference('127.0.0.1') | first}} -s {{b9.zones[domain]['master']}}
    - require:
      - file: /root/.bind/credentials
      - file: /usr/local/bin/bind_ddns.py

delete_secrets:
  cmd.run:
    - name: rm /root/.bind/credentials
    - require:
      - file: /root/.bind/credentials
    - onchanges:
      - cmd: register host
    - order: 100020

