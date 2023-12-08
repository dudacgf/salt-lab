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
{%- set domain = pillar[pillar.location + '_domain'] %}
{%- set domainname = hostname + '.' + domain %}
{%- set domainemail = pillar.contact %}

# installs godaddy's ACME dns authenticator
install certbot-dns-godaddy:
  cmd.run:
    - name: pip3 -q install 'certbot-dns-godaddy==2.6.0'
  
pip3 -q install zope.interface:
  cmd.run:
    - require:
      - cmd: install certbot-dns-godaddy
    - onlyif:
      - fun: 'match.grain'
        tgt: 'os_family:RedHat'

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
    - require:
      - cmd: install certbot-dns-godaddy

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
    - require:
      - cmd: install certbot-dns-godaddy

#
# gera o novo certificado
{% set flag_certbot_run = salt['grains.get']('flag_certbot_run', False) %}
{% if not flag_certbot_run %}
run_certbot:
  cmd.run:
    - name: certbot certonly --authenticator dns-godaddy --dns-godaddy-credentials /root/.godaddy/godaddy_config.ini --dns-godaddy-propagation-seconds 60 --email={{ domainemail }} --agree-tos --manual-public-ip-logging-ok --post-hook /usr/local/bin/post_hook.sh --reinstall --no-eff-email -d {{ domainname }}

    - require:
      - file: copia *
      #TODO.       - pkg: certbot pkgs
      - cmd: install certbot-dns-godaddy

flag_certbot_run:
  grains.present:
    - value: True
    - require: 
      - cmd: run_certbot

{% else %}

'-- Server already has certificate. Not running certbot.':
  test.nop

{% endif %} # certbot

