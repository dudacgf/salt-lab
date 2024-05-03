#
## named.sls - installs a bind9 dns named server
#
## ecgf - apr/2024
#

{%- import_yaml "maps/pkgs_data/by_os_family.yaml" as pkg_data %}
{%- set pkg_data = grains.items.filter_by(pkg_data) %}

{{ pkg_data.bind.name }}:
  pkg.installed

/etc/named.conf:
  file.managed:
    - source: salt://files/services/named/named.conf.jinja
    - template: jinja
    - user: root
    - group: named
    - mode: 640

{% if 'named' in pillar %}
{% for zone_name in pillar.named.zones %}
{% set zone = pillar.named.zones[zone_name] %}
{% if zone['type'] == 'primary' %}
/var/named/data/primary/{{zone_name}}.dns:
  file.managed:
    - user: named
    - group: named
    - mode: 0640
    - makedirs: True
    - dir_mode: 0750
    - contents: |
              $ORIGIN .
              $TTL 86400     ; 1 day
              {{ zone_name }}  IN SOA {{ zone['mname'] }}. {{ zone['rname'] }}. (
                  {{ "today" | strftime("%Y%m%d") }}01 ; serial
                  10800      ; refresh (3 hours)
                  3600       ; retry (1 hour)
                  604800     ; expire (1 week)
                  86400      ; minimum (1 day)
              )
                             NS {{ grains.fqdn }}
              {%- for z in zone['secondaries'] %}
                             NS {{ z['name'] }}
              {%- endfor %}
{%- elif zone['type'] == 'secondary' %}
{{ zone['name'] }} create secondary data dir:
  file.directory:
    - name: /var/named/data/secondary
    - user: named
    - group: named
    - mode: 750
{%- endif %} {# zone is primary #}
{%- endfor %}
{%- endif %}
 
{{ pkg_data.bind.service }}:
  service.running:
    - enable: True
    - restart: True
    - watch:
      - file: /etc/named.conf
      
