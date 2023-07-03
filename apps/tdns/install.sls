#
## technitium.sls - instala free opensource dns technitium
#

#
# instala o pacote

{% if not grains['flag_technitium_dns_installed'] | default(False) or salt.tdns.check_update() %}
download installer:
  file.managed:
    - name: /tmp/install.sh
    - source: https://download.technitium.com/dns/install.sh
    - skip_verify: True
    - verify_ssl: False
    - mode: 755

run installer:
  cmd.run:
    - name: /tmp/install.sh
    - shell: /bin/bash
    - cwd: /tmp
    - require:
      - file: download installer

flag_technitium_dns_installed:
  grains.present:
    - value: True
    - require:
      - cmd: run installer

#
## habilita o servico
dns.service:
  service.running:
    - enable: true
    - restart: true

{% else %}

run installer:
  test.nop:
  - name: 'technitium dns installed and no updates needed'

{% endif %}

