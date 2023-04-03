#
## service_specific/init.sls - verifica se há services no pillar de um servidor
#                           e chama os state files correspondentes

{% set services = pillar.get('services', {}) %}
{% for service in services %}

# e tem coisa que tá em linux_services
{% include 'linux_services/' + service + '.sls' ignore missing %}
{% include 'linux_services/' + service + '/init.sls' ignore missing %}

{% endfor %}
