#
## zabbix-proxy - installs zabbix proxy via zabbix official repos
#

{% include 'environment/zabbix-repo.sls' %}

{% if grains['os_family'] == 'RedHat' and pillar['selinux_mode'] | default('disabled') == 'enforcing' %}
{% set install_selinux_policy = ', zabbix-selinux-policy' %}
{% else %}
{% set install_selinux_policy = '' %}
{% endif %}

install zabbix proxy:
  pkg.installed:
    - pkgs: [zabbix-proxy-mysql, zabbix-sql-scripts {{ install_selinux_policy }} ]
    - require:
      - zabbix repo

