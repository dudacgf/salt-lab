timezone: America/Sao_Paulo
locale: pt_BR.UTF-8
langpack: pt
{% if grains.os_family == 'Debian' %}
keymap: br-abnt2
{% elif grains.os_family == 'RedHat' %}
keymap: br
{% else %}
keymap: us-intl
{% endif %}

name: International Enterprise co.
nickname: enterprise
address: 99 Dummy Street
city: ACity
provincy/state: AProvince
country: AA
contact: abuse@example.com

internal_domain: internal.example.com
external_domain: example.com
zabbix_agent_install: True
zabbix_server: zabbix.internal.example.com

virt_provider: a cloud.provider
virtual_host: the_host (must be a minion)
salt_server: salt.internal.example.com
salt_server_ip: 192.168.10.100
audit2graylog: False
audit2graylog_tls: False
audit2graylog: False
graylog_server: graylog.internal.example.com

proxy: false
