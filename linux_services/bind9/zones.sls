{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}
{%- import_yaml "maps/services/bind9/" + pillar.bind_map | default('bind9') + ".yaml" as b9 %}

{% if 'zones' in pillar.named %}
{%- for zone_name in pillar.named.zones | default([]) %}
{%- set zone = b9.zones[zone_name] %}

{%- if pillar.named.zones[zone_name].role == 'forwarder' %}
"{{ pkg_data.named.conf_dir }}/{{zone_name}}-def.zone":
  file.managed:
    - user: {{ pkg_data.named.user }}
    - group: {{ pkg_data.named.group }}
    - mode: 0640
    - contents: |
        zone "{{ zone_name }}" {
            type forward;
            forwarders {
{%- for s in pillar.named.zones[zone_name].forwarders %}
                 {{ s }};
{%- endfor %}
            };
        };

{% else %}

# master and slaves transfer and update keys (if used)
{{pkg_data.named.conf_dir}}/{{zone_name}}-transfer-key:
  file.managed:
    - user: {{ pkg_data.named.user }}
    - group: {{ pkg_data.named.group }}
    - mode: 0640
    - contents: | 
        key "{{ zone.transfer_key.name }}" {
            algorithm "{{ zone.transfer_key.algorithm }}";
            secret "{{ zone.transfer_key.secret }}";
        };
{%- if zone.allow_updates | default(True) %}
{{pkg_data.named.conf_dir}}/{{zone_name}}-update-key:
  file.managed:
    - user: {{ pkg_data.named.user }}
    - group: {{ pkg_data.named.group }}
    - mode: 0640
    - contents: | 
        key "{{ zone.update_key.name }}" {
            algorithm "{{ zone.update_key.algorithm }}";
            secret "{{ zone.update_key.secret }}";
        };
{%- endif %}

{%- if pillar.named.zones[zone_name].role == 'master' %} #primary zone
"{{ pkg_data.named.conf_dir }}/{{zone_name}}-def.zone":
  file.managed:
    - user: {{ pkg_data.named.user }}
    - group: {{ pkg_data.named.group }}
    - mode: 0640
    - contents: |
        zone "{{ zone_name }}" {
             type master;
             file "data/primary/{{ zone_name }}.dns";
             allow-transfer { key {{zone_name}}-transfer-key; };
{%- if zone.allow_updates | default(True) %}
             allow-update { key {{zone_name}}-update-key; };
{%- endif %}
        };
 
/var/named/data/primary/{{zone_name}}.dns:
  file.managed:
    - user: {{ pkg_data.named.user }}
    - group: {{ pkg_data.named.group }}
    - mode: 0640
    - makedirs: True
    - dir_mode: 0750
    - contents: |
        $ORIGIN .
        $TTL 86400     ; 1 day
        {{ zone_name }}  IN SOA {{ zone['mname'] }}. {{ zone['rname'] }}. (
            {{ "today" | strftime("%Y%m%d") }}01 ; serial
            3h         ; refresh (3 hours)
            1h         ; retry (1 hour)
            1w         ; expire (1 week)
            1d         ; minimum (1 day)
        )
                             NS {{ grains.fqdn }}
              {%- for z in pillar.named.zones[zone_name].secondaries %}
                             NS {{ z['name'] }}
              {%- endfor %}
    - unless: test -f /var/named/data/primary/{{zone_name}}.dns

{%- elif pillar.named.zones[zone_name].role == 'slave' %}
"{{ pkg_data.named.conf_dir }}/{{zone_name}}-def.zone":
  file.managed:
    - user: {{ pkg_data.named.user }}
    - group: {{ pkg_data.named.group }}
    - mode: 0640
    - contents: |
        zone "{{ zone_name }}" {
             type slave;
             file "data/secondary/{{ zone_name }}.dns";
             masters { 
                  {{pillar.named.zones[zone_name].primary}} key {{zone_name}}-transfer-key;
             };
        };

{{ zone_name }} create secondary data dir:
  file.directory:
    - name: /var/named/data/secondary
    - user: {{ pkg_data.named.user }}
    - group: {{ pkg_data.named.group }}
    - mode: 750

{%- endif %} {# zone is primary #}
{%- endif %} {# zone is forwarder #}
{%- endfor %}
{%- else %}
'-- no zones defined in bind map': test.nop
{%- endif %}
