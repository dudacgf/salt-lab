#
# sethostname.sls - configura o hostname de um minion
#

{%- if not pillar['set_hostname'] | default(False) %}
{% include 'environment/hostname/sethostname.sls' %}
{% endif %}

{% if pillar['register_dns'] | default(False) %}

{% if pillar['dns_hoster'] in pillar['supported_dns_hosters'] %}
{% include 'environment/hostname/' + pillar['dns_hoster'] + '.sls' ignore missing %}
{% else %}
'=== register A record for this type of dns hosting is not implemented. sorry ===':
  test.nop
{% endif %} # if pillar['dns_hoster']

{% endif %} # if pillar['register_dns']
