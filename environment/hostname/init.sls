#!jinja|yaml
#
# sethostname.sls - configura o hostname de um minion
#

{%- if pillar['set_hostname'] | default(False) %}
{% include 'environment/hostname/sethostname.sls' %}
{% endif %}

{% if pillar['register_dns'] | default(False) %}
    {% set location = pillar['location'] %}
    {% set domain = pillar[location + '_domain'] %}
    {% if domain in pillar['dns_hoster_by_domain'] %}
        {% set hoster = pillar['dns_hoster_by_domain'][domain] %}
        {% include 'environment/hostname/' + hoster + '.sls' ignore missing %}
    {% else %}
'-- register A record for {{ domain }} at {{ hoster }} is not implemented.':
  test.nop
    {% endif %} # if domain in 
{% else %}
'-- will not register this host in dns':
  test.nop
{% endif %} # if pillar['register_dns']
