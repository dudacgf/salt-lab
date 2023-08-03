#
# sethostname.sls - configura o hostname de um minion
#

{%- if not pillar['set_hostname'] | default(False) %}
leave hostname:
  test.show_notification:
    - text: '*** Esse mínion vai permanecer com o mesmo hostname. nada a fazer ***'

{% else %}
{%- set hostname = grains['id'].split('.')[0] %}
{% set location = pillar.get('location', 'internal') %}
{% set domain = salt['pillar.get'](location + '_domain', 'local') %}

#
## hostnamectl primeiro
/usr/bin/hostnamectl set-hostname {{ hostname }}.{{ domain }}:
  cmd.run

#
## depois nmcli
nmcli general hostname {{ hostname }}.{{ domain }}:
  cmd.run

/etc/hosts:
  file.append:
    - text: 
      - 127.0.0.1   {{ hostname }}.{{ domain }}
      - ::1         {{ hostname }}.{{ domain }}
      - {{ pillar['salt_server_ip'] }} {{ pillar['salt_server'] }}

{% endif %}

{% if pillar['register_dns'] | default(False) %}

{% if pillar['dns_hoster'] in pillar['supported_dns_hosters'] %}
{% include 'environment/hostname/' + pillar['dns_hoster'] + '.sls' ignore missing %}
{% else %}
'=== register A record for this type of dns hosting is not implemented. sorry ===':
  test.nop
{% endif %} # if pillar['dns_hoster']

{% endif %} # if pillar['register_dns']
