# register a minion in bind9 dns server
{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
{%- import_yaml "maps/services/bind9/" + pillar.bind_map | default('bind9') + ".yaml" as b9 %}
{%- set last_zone = b9.zones | last %}
{%- set first_zones = b9.zones | difference(last_zone) | default([]) %}
/root/.bind/credentials:
  file.managed:
    - makedirs: True
    - user: root
    - group: root
    - mode: 400
    - contents: |
        { 
{%- for zone_name in first_zones %}
{%- set zone = b9.zones[zone_name] %}
            "{{ zone.update_key.name }}.": "{{ zone.update_key.secret }}",
{%- endfor %}
{%- set zone = b9.zones[last_zone] %}
            "{{ zone.update_key.name }}.": "{{ zone.update_key.secret }}"
        }

{%- set zone = b9.zones[grains.domain] %}
{{ grains.host }} register dns:
  ddns.present:
    - zone: {{ grains.domain }}
    - ttl: 60
    - data: {{ grains.ipv4 | difference(['127.0.0.1']) | first }}
    - nameserver: {{ salt.dig.A(zone.master) | first }}
    - keyfile: /root/.bind/credentials
    - keyname: {{ zone.update_key.name }}
    - keyalgorithm: {{ zone.update_key.algorithm }}
