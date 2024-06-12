/root/wazuh-install.sh:
  file.managed:
    - source: https://packages.wazuh.com/4.7/config.yml
    - skip_verify: true
    - mode: 755


