#
## certbot/aws.sls - generates certificate for a minion when the dns_hosters
#

{% set hostname = grains.id.split('.')[0] %}
{% set location = pillar['location'] %}
{% set domain = pillar[location + '_domain'] %}
{% set domainname = hostname + '.' + domain %}
{% set domainemail = pillar['contact'] %}

python3-certbot-dns-route53:
  pkg.installed

{{ sls }} copy aws files:
  file.managed:
    - template: jinja
    - makedirs: True
    - user: root
    - group: root
    - mode: 600
    - names:
      - /root/.aws/credentials:
        - source: salt://files/secrets/aws-credentials.jinja
      - /root/.aws/config:
        - contents: |
            [default]

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
## gera o novo certificado
run certbot:
  cmd.run:
    - name: certbot certonly --dns-route53 --email={{ domainemail }} --reinstall --no-eff-email --agree-tos --post-hook /usr/local/bin/post_hook.sh -d {{ domainname }} 
    - require:
      - file: {{ sls }} copy aws files
      #      - pkg: certbot pkgs

aws delete secrets:
  file.absent:
    - name: /root/.aws/credentials
    - require:
      - file: {{ sls }} copy aws files

flag_certbot_run:
  grains.present:
    - value: True
    - require: 
      - cmd: run certbot

