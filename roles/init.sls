#
## role_specific/init.sls - verifica se há roles no pillar de um servidor
#                           e chama os state files correspondentes

{% set roles = pillar.get('roles', {}) %}
{% if roles %}
{% for role in roles %}

# tem coisa que tá em roles
{% include 'roles/' + role + '.sls' ignore missing %}
{% include 'roles/' + role + '/init.sls' ignore missing %}


{% endfor %}
{% else %}
'== no roles to be installed ==':
  test.nop
{% endif %}
