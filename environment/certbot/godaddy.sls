#!jinja|yaml

# 
## certbot.sls - instala certbot, gera certificado
#
## (c) ecgf - Jun/2021
# 
##

#
# obtém grains e pillars necessários
{%- set hostname = grains.id.split('.')[0] %}
{%- set location = pillar['location'] %}
{%- set domain = pillar[location + '_domain'] %}
{%- set domainname = hostname + '.' + domain %}
{%- set domainemail = pillar['contact'] %}

# installs godaddy's ACME dns authenticator
pip3 -q install certbot-dns-godaddy:
  cmd.run

# correct script (previous version works, current doesn't)
# TODO: check new version
{{ pillar.pkg_data.certbot_godaddy_script }}:
  file.managed:
    - source: salt://files/scripts/certbot_dns_godaddy.py

# --dns-godaddy-credentials
copia config.ini:
  file.managed:
    - name: /root/.godaddy/godaddy_config.ini
    - source: salt://files/secrets/godaddy_config.ini.jinja
    - template: jinja
    - makedirs: True
    - dir_mode: 700
    - user: root
    - group: root
    - mode: 400

#
## post process hook
copia post_hook.sh:
  file.managed:
    - name: /usr/local/bin/post_hook.sh
    - source: salt://files/services/certbot/post_hook.sh.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 750

#
# gera o novo certificado
{% set flag_certbot_run = salt['grains.get']('flag_certbot_run', False) %}
{% if not flag_certbot_run %}
run_certbot:
  cmd.run:
    - name: certbot certonly --authenticator dns-godaddy --dns-godaddy-credentials /root/.godaddy/godaddy_config.ini --dns-godaddy-propagation-seconds 60 --email={{ domainemail }} --agree-tos --manual-public-ip-logging-ok --post-hook /usr/local/bin/post_hook.sh --reinstall --no-eff-email -d {{ domain }},{{ domainname }}

    - require:
      - file: copia *
      - pkg: certbot pkgs

flag_certbot_run:
  grains.present:
    - value: True
    - require: 
      - cmd: run_certbot

{% else %}

'-- Server already has certificate. Not running certbot.':
  test.nop

{% endif %} # certbot

