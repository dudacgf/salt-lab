## redhat are all the same but debian and ubuntu not (f**k ubuntu)
{% set osf = grains['os_family'] | lower() %}
{% if osf != 'redhat' %}
{% set osf = grains['os'] | lower() %}
{% endif %}

'-- executando os_specific para {{ osf }}':
  test.nop

## note to me: path always from salt-base
{% include 'init/os_specific/' + osf + '.sls' ignore missing %}

