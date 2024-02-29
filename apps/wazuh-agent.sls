{% if grains['os_family'] == 'RedHat' %}
import key:
  cmd.run:
    - name: rpm --import https://packages.wazuh.com/key/GPG-KEY-WAZUH

add wazuh repo:
  file.managed:
    - name: /etc/yum.repos.d/wazuh.repo
    - contents: |
          [wazuh]
          gpgcheck=1
          gpgkey=https://packages.wazuh.com/key/gpg-key-wazuh
          enabled=1
          name=el-\$releasever - wazuh
          baseurl=https://packages.wazuh.com/4.x/yum/
          protect=1

deploy agent:
  cmd.run:
    - name: "WAZUH_MANAGER={{ pillar['wazuh']['manager'] }} WAZUH_REGISTRATION_SERVER={{ pillar['wazuh']['regserver'] }} yum install wazuh-agent -y"
    - require:
      - cmd: import key
      - file: add wazuh repo
{% elif grains['os_family'] == 'Debian' %}
import key:
  cmd.run:
    - name: "curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --dearmour > /etc/apt/trusted.gpg.d/wazuh.gpg"

add wazuh repo:
  file.managed:
    - name: /etc/apt/sources.list.d/wazu.list
    - contents: |
          deb [signed-by=/etc/apt/trusted.gpg.d/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main

apt-get update: cmd.run

deploy agent:
  cmd.run:
    - name: "WAZUH_MANAGER={{ pillar['wazuh']['manager'] }} WAZUH_REGISTRATION_SERVER={{ pillar['wazuh']['regserver'] }} apt-get install wazuh-agent -y"
    - require:
      - cmd: import key
      - file: add wazuh repo
{% else %}
'-- OS not supported': test.no
{% endif %}

wazuh-agent:
  service.running:
    - enable: True
    - restart: True
