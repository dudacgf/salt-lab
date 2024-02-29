#
### simple_shorewall.sls
##    installs a very simple shorewall configuration
#
# ecgf - fev/2024
#

instala shorewall:
  pkg.installed:
    - name: shorewall
    - refresh: True

configura shorewall.conf:
  file.managed:
    - name: /etc/shorewall/shorewall.conf
    - source: salt://files/services/shorewall/shorewall.conf
    - require:
      - instala shorewall

/etc/shorewall/zones:
  file.managed:
    - user: root
    - group: root
    - mode: 0600
    - contents: |
          fw  firewall
          pub ipv4

{% set iface = salt.ifaces.get() | difference('lo') | first %}
/etc/shorewall/interfaces:
  file.managed:
    - user: root
    - group: root
    - mode: 0600
    - contents: |
          pub {{ iface }} - dhcp 

/etc/shorewall/policy:
  file.managed:
    - user: root
    - group: root
    - mode: 0600
    - contents: |
          fw all REJECT
          pub all DROP

/etc/shorewall/rules:
  file.managed:
    - user: root
    - group: root
    - mode: 0600
    - contents: |
          ?SECTION ALL
          ?SECTION ESTABLISHED
          ?SECTION RELATED
          ?SECTION INVALID
          ?SECTION UNTRACKED
          ?SECTION NEW
          {%- for rule in pillar['simple_shorewall']['rules_out'] %}
          ACCEPT fw pub {{ rule }}
          {%- endfor %}
          {%- for rule in pillar['simple_shorewall']['rules_in'] %}
          ACCEPT pub fw {{ rule }}
          {%- endfor %}
          ACCEPT fw  pub udp  domain
          ACCEPT all all icmp echo-request,echo-reply

restart shorewall service:
  service.running:
    - name: shorewall
    - enable: True
    - restart: True
    - watch:
      - file: /etc/shorewall/shorewall.conf
      - file: /etc/shorewall/zones
      - file: /etc/shorewall/interfaces
      - file: /etc/shorewall/policy
      - file: /etc/shorewall/rules

stop firewalld:
  service.dead:
    - name: firewalld.service
    - enable: False
    - require:
      - service: restart shorewall service
    - onlyif:
      - fun: match.grain
        tgt: 'os_family:RedHat'

stop ufw:
  service.dead:
    - enable: False
    - require:
      - service: restart shorewall service
    - name: ufw.service
    - onlyif:
      - fun: match.grain
        tgt: 'os_family:Debian'


  
