{% if grains['os_family'] == 'RedHat' and 
      pillar['selinux_mode'] | default('enforced') | lower() == 'enforcing' %}

ajusta selinux:
  cmd.script:
    - source: salt://files/scripts/nextcloud_selinux.sh
    - env:
      - TEMP: /root

{% endif %}

