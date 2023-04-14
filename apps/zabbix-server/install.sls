#
## zabbix-server - installs zabbix server via zabbix official repos
#

{% include 'environment/zabbix-repo.sls' %}

{% if grains['os_family'] == 'RedHat' and pillar['selinux_mode'] | default('disabled') == 'enforcing' %}
{% set install_selinux_policy = ', zabbix-selinux-policy' %}
{% else %}
{% set install_selinux_policy = '' %}
{% endif %}

install zabbix server:
  pkg.installed:
    - pkgs: [zabbix-server-mysql, zabbix-web-mysql, zabbix-apache-conf, zabbix-sql-scripts {{ install_selinux_policy }}, zabbix-agent]
    - require:
      - zabbix repo

