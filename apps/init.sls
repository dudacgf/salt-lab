#
## role_specific/init.sls - verifica se há roles no pillar de um servidor
#                           e chama os state files correspondentes

{% set apps = pillar.get('apps', []) %}
{% if apps %}
{% for app in apps %}

{% include 'apps/' + app + '.sls' ignore missing %}
{% include 'apps/' + app + '/init.sls' ignore missing %}

{% endfor %}
{% else %}
'-- no apps to be installed.':
  test.nop
{% endif %}
