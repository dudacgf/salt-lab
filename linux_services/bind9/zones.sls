{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}

{%- if 'named' in pillar %}
{%- for zone_name in pillar.named.zones | default([]) %}
{%- set zone = pillar.named.zones[zone_name] %}
{%- if zone.type == 'primary' %} #primary zone
{%- set tsig_key = salt.cmd.run('tsig-keygen -a hmac-sha512 ' + zone_name + '-transfer-key') %}
{{pkg_data.named.conf_dir}}/{{zone_name}}-transfer-key:
  file.managed:
    - user: {{ pkg_data.named.user }}
    - group: {{ pkg_data.named.group }}
    - mode: 0640
    - contents: | 
       {{ tsig_key | indent(8) }} 
    - unless: test -f {{pkg_data.named.conf_dir}}/{{zone_name}}-transfer-key
{%- if zone.allow_updates | default(True) %}
{{pkg_data.named.conf_dir}}/{{zone_name}}-update-key:
  file.managed:
    - user: {{ pkg_data.named.user }}
    - group: {{ pkg_data.named.group }}
    - mode: 0640
    - contents: | 
        key "{{ zone.update_key.name }}-update-key " {
            algorithm "{{ zone.update_key.algorithm }}";
            secret "{{ zone.update_key.secret }}";
        };
    - unless: test -f {{pkg_data.named.conf_dir}}/{{zone_name}}-update-key
{%- endif %}

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
              {%- for z in zone['secondaries'] %}
                             NS {{ z['name'] }}
              {%- endfor %}
    - unless: test -f /var/named/data/primary/{{zone_name}}.dns

{%- elif zone.type == 'secondary' %}
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
                  {{ zone['primary'] }} key {{zone_name}}-transfer-key;
             };
        };

{{ zone_name}} scp transfer-key from primary:
  module.run:
    - scp.get:
      - hostname: {{ zone.primary }}
      - remote_path: {{pkg_data.named.conf_dir}}/{{zone_name}}-transfer-key
      - local_path: {{pkg_data.named.conf_dir}}/{{zone_name}}-transfer-key
      - key_filename: /root/.ssh/salt_vg_ed25519
      - allow_agent: False
      - auto_add_policy: True

{{ zone_name }} set key permissions:
  file.managed:
    - name: {{pkg_data.named.conf_dir}}/{{zone_name}}-transfer-key
    - user: {{ pkg_data.named.user }}
    - group: {{ pkg_data.named.group }}
    - mode: 640

{{ zone_name }} create secondary data dir:
  file.directory:
    - name: /var/named/data/secondary
    - user: {{ pkg_data.named.user }}
    - group: {{ pkg_data.named.group }}
    - mode: 750

{%- elif zone.type == 'forwarder' %}
"{{ pkg_data.named.conf_dir }}/{{zone_name}}-def.zone":
  file.managed:
    - user: {{ pkg_data.named.user }}
    - group: {{ pkg_data.named.group }}
    - mode: 0640
    - contents: |
        zone "{{ zone_name }}" {
            type forward;
            forwarders {
{%- for s in zone['forwarders'] %}
                 {{ s }};
{%- endfor %}
            };
        };

{%- endif %} {# zone is primary #}
{%- endfor %}
{%- else %}
"--- no info found: 'pillar.named' not found": test.nop
{%- endif %}
