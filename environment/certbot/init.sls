#
## certbot.sls - installs certbot and generates a certificate
#

{%- if pillar['certbot'] | default(False) %}
#
# install pkgs
certbot:
  pkg.installed

{{ pillar['pkg_data']['python']['dnspython'] }}:
  pkg.installed

# you just need to run it once
{% if not grains['flag_certbot_run'] | default(False) %}

# calls certbot for the dns hoster used for this server
{%- if pillar['dns_hoster'] in pillar['supported_dns_hosters'] %}
{% include 'environment/certbot/' + pillar['dns_hoster'] + '.sls' ignore missing %}
{%- else %}
'*** dns hoster not supported: {{ pillar['dns_hoster'] }} ***':
  test.fail_without_changes
{%- endif %} # if dns_hoster
{% else %}
'*** Server already has certificate. Not running certbot. ***':
  test.nop
{% endif %} # if flag_certbot_run
{%- else %}
'*** Server does not need certificate. Not running certbot. ***':
  test.nop
{% endif %} # if pillar['certbot']
