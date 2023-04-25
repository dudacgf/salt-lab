# this pillar file includes a hosts/host_name.sls file in the top.sls file
# this way, I can use different pillar values for different hosts
# see hosts/hosts_sample.sls for a list of pillar values used in formulas and states
#

## note to me: path always from salt-base
{% set filename = grains.id.split('.')[0] %}
{% include 'hosts/' + filename + '.sls' ignore missing %}

