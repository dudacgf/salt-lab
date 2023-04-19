## note to me: path always from salt-base
# this pillar file includes a hosts/host_name.sls file in the top.sls file
# this way, I can use different pillar values for different hosts
{% set filename = grains.id.split('.')[0] %}
{% include 'hosts/' + filename + '.sls' ignore missing %}

