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

{% if pillar.get('register_dns', False) %}

/tmp/godaddy_secrets:
  file.managed:
    - source: salt://files/secrets/godaddy_config.jinja
    - template: jinja
    - mode: 400

/tmp/godaddy_ddns.py:
  file.managed:
    - source: salt://files/scripts/godaddy_ddns.py
    - mode: 500

'python3 /tmp/godaddy_ddns.py %/tmp/godaddy_secrets':
  cmd.run

delete_secrets:
  cmd.run:
    - name: rm /tmp/godaddy_secrets
    - order: last
{% endif %}
