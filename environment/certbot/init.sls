#
## certbot.sls - installs certbot and generates a certificate
#

{%- if pillar['certbot'] | default(False) %}
certbot pkgs:
  pkg.installed:
    - pkgs:
      - certbot
      - {{ pillar['pkg_data']['python']['dnspython'] }}

  {% if not grains['flag_certbot_run'] | default(False) %}
      {% set location = pillar['location'] %}
      {% set domain = pillar[location + '_domain'] %}
      {% if domain in pillar['dns_hoster_by_domain'] and domain in pillar['certbot_ok_domains'] %}
        {% set hoster = pillar['dns_hoster_by_domain'][domain] %}
        {% include 'environment/certbot/' + hoster + '.sls' ignore missing %}
      {% else %}
'-- certbot for {{ domain }} not implemented.':
  test.nop
      {%- endif %}
  {% else %}
'-- Server already has certificate. Not running certbot.':
  test.nop
  {% endif %} # if flag_certbot_run
{%- else %}
'-- Server does not need certificate. Not running certbot.':
  test.nop
{% endif %} # if pillar['certbot']
