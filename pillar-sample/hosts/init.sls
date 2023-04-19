## note to me: path always from salt-base
{% set filename = grains.id.split('.')[0] %}
{% include 'hosts/' + filename + '.sls' ignore missing %}

