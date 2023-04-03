#
# 
##
#
## certbot.sls - instala certbot, gera certificado
#
## (c) ecgf - Jun/2021
# 
##

{%- if pillar.get('certbot', False) %}

#
# obtém grains e pillars necessários
{% set hostname = grains.id.split('.')[0] %}
{% set domain = pillar['external_domain'] %}
{% set domainname = hostname + '.' + domain %}
{% set domainemail = pillar['contact'] %}

#
# instala pacotes necessários
certbot:
  pkg.installed

{{ pillar['pkg_data']['python']['dnspython'] }}:
  pkg.installed

#
# scripts para validação
copia validation.py:
  file.managed:
    - name: /usr/local/bin/validation.py
    - source: salt://files/services/certbot/validation.py.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 750

copia cleanup.py:
  file.managed:
    - name: /usr/local/bin/cleanup.py
    - source: salt://files/services/certbot/cleanup.py
    - user: root
    - group: root
    - mode: 750

#
# arquivo com chaves para validação
copia config.ini:
  file.managed:
    - name: /usr/local/bin/godaddy_config.ini
    - source: salt://files/secrets/godaddy_config.ini.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 640

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
    - name: certbot certonly --manual --preferred-challenges=dns-01 --email={{ domainemail }} --agree-tos --manual-public-ip-logging-ok --manual-auth-hook /usr/local/bin/validation.py --manual-cleanup-hook /usr/local/bin/cleanup.py --post-hook /usr/local/bin/post_hook.sh --reinstall --no-eff-email -d {{ domainname }}
    - require:
      - file: copia *
      - pkg: certbot
      - pkg: {{ pillar['pkg_data']['python']['dnspython'] }}

flag_certbot_run:
  grains.present:
    - value: True
    - require: 
      - cmd: run_certbot

{% else %}

'*** Server already has certificate. Not running certbot. ***':
  test.nop

{% endif %}

{% else %}

'*** Server does not need certificate. Not running certbot. ***':
  test.nop

{% endif %} # certbot

