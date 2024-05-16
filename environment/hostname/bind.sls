{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
# register a minion in aws route53 dns
python3-{{pkg_data.python3.dnspython}}:
  pkg.installed

{% set domain = pillar[pillar.location + '_domain'] %}
/root/.bind/credentials:
  file.managed:
    - makedirs: True
    - user: root
    - group: root
    - mode: 400
    - contents: |
        {{ grains.domain }}:
           name: {{ pillar.bind[domain]['name'] }}
           secret: {{ pillar.bind[domain]['secret'] }}

/usr/local/bin/bind_ddns.py:
  file.managed:
    - source: salt://files/scripts/bind_ddns.py
    - user: root
    - group: root
    - mode: 0755

register host:
  cmd.run:
    - name: /usr/local/bin/bind_ddns.py -k /root/.bind/credentials -t A -z {{domain}} -d {{grains.id.split('.')[0]}} -i {{grains.ipv4 | difference('127.0.0.1') | first}} -s {{pillar.bind[domain]['primary']}}
    - require:
      - file: /root/.bind/credentials
      - file: /usr/local/bin/bind_ddns.py

delete_secrets:
  cmd.run:
    - name: rm /root/.bind/credentials
    - require:
      - file: /root/.bind/credentials
    - order: 100020

