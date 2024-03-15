#
### simple_shorewall6.sls 
##    installs a very simple shorewall6 configuration
#
# ecgf - fev/2024
#

instala shorewall6:
  pkg.installed:
    - name: shorewall6
    - refresh: True

enable startup:
  file.replace:
    - name: /etc/shorewall6/shorewall6.conf
    - pattern: '^STARTUP_ENABLED=No'
    - repl: 'STARTUP_ENABLED=Yes'

/etc/shorewall6/zones:
  file.managed:
    - user: root
    - group: root
    - mode: 0600
    - contents: |
          fw  firewall
          pub ipv6

{% set iface = salt.ifaces.get() | difference('lo') | first %}
/etc/shorewall6/interfaces:
  file.managed:
    - user: root
    - group: root
    - mode: 0600
    - contents: |
          pub {{ iface }} - dhcp 

/etc/shorewall6/policy:
  file.managed:
    - user: root
    - group: root
    - mode: 0600
    - contents: |
          fw all REJECT
          pub all DROP

{%- set services = ['prometheus-'] | product(pillar.get('prometheus_exporters',[])) | map('join') | list %}
{%- do services.extend(pillar.services | default([])) %}
{%- do services.extend(pillar.basic_services | default([])) %}
{%- import_yaml "maps/services/shorewall/ports.sls" as sp %}
/etc/shorewall6/rules:
  file.managed:
    - user: root
    - group: root
    - mode: 0640
    - contents: |
          ?SECTION ESTABLISHED
          ?SECTION RELATED
          ?SECTION INVALID
          ?SECTION UNTRACKED
          ?SECTION NEW
          {%- for rule in pillar['simple_shorewall']['rules_out'] %}
          ACCEPT fw pub {{ rule }}
          {%- endfor %}
          ACCEPT fw  pub udp  domain
          {%- for rule in pillar['simple_shorewall']['rules_in'] %}
          ACCEPT pub fw {{ rule }}
          {%- endfor %}
{%- for service in services %}
{%-     if service in sp %}
{%-         for protocol in sp[service] %}
          ACCEPT pub fw {{ protocol }} {{ sp[service][protocol] }}
{%-         endfor %}
{%-     endif %}
{%- endfor %}
          ACCEPT all all icmp echo-request,echo-reply

restart shorewall6 service:
  service.running:
    - name: shorewall6
    - enable: True
    - restart: True
    - watch:
      - file: /etc/shorewall6/zones
      - file: /etc/shorewall6/interfaces
      - file: /etc/shorewall6/policy
      - file: /etc/shorewall6/rules

stop6 firewalld:
  service.dead:
    - name: firewalld.service
    - enable: False
    - require:
      - service: restart shorewall6 service
    - onlyif:
      - fun: match.grain
        tgt: 'os_family:RedHat'

stop6 ufw:
  service.dead:
    - enable: False
    - require:
      - service: restart shorewall6 service
    - name: ufw.service
    - onlyif:
      - fun: match.grain
        tgt: 'os_family:Debian'

