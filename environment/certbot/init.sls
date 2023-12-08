#
## certbot.sls - installs certbot and generates a certificate
#

{% set domain = pillar[pillar.location + '_domain'] %}

{% if grains['flag_certbot_run'] | default(False) %}
'-- Server already has certificate. Not running certbot.':
  test.nop
{% elif not domain in pillar['dns_hoster_by_domain'] or not domain in pillar['certbot_ok_domains'] %}
'-- certbot for {{ domain }} not implemented.':
  test.nop
{%- elif not pillar['certbot'] | default(False) %}
'-- Server does not need certificate. Not running certbot.':
  test.nop
{%- else %}
## TODO - check godaddy-dns-certbot new version with corrections
"pip3 -q install 'certbot==2.6.0' dnspython":
  cmd.run 

{# TODO - idem
certbot pkgs:
  pkg.installed:
    - pkgs:
      - '{{ pillar.pkg_data.certbot }}==2.6.0'
      - {{ pillar.pkg_data.python3.version }}-{{ pillar.pkg_data.python3.dnspython }}

python3-{{ pillar.pkg_data.python3.dnspython }}:
  pkg.installed:
    - onlyif:
      - fun: 'match.grain'
        tgt: 'os_family:Suse'
#}
{% set hoster = pillar['dns_hoster_by_domain'][domain] %}
{% include 'environment/certbot/' + hoster + '.sls' ignore missing %}
{% endif %} 
