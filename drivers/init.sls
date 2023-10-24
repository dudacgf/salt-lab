#
## drivers/init.sls - verifica se há drivers para instalar no pillar de um servidor
#                           e chama os state files correspondentes

{% set drivers = pillar.get('drivers', {}) %}
{% if drivers %}
{% for driver in drivers %}

# tem coisa que tá em drivers
{% include 'drivers/' + driver + '.sls' ignore missing %}
{% include 'drivers/' + driver + '/init.sls' ignore missing %}


{% endfor %}
{% else %}
'== no drivers to be installed ==':
  test.nop
{% endif %}
