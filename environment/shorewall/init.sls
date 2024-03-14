#
### shorewall.sls - installs and configures shorewall - iptables/nftables firewall
#
# ecgf - fev/2024
#

#
# redhat 8 and up doesn't offer shorewall anymore
{%- if grains['os_family'] == 'RedHat' and grains['osmajorrelease'] >= 8 %}
shorewall repo:
  pkgrepo.managed:
    - name: 'copr_shorewall'
    - file: /etc/yum.repos.d/shorewall_copr.repo
    - humanname: Copr repo for shorewall owned by pgfed
    - baseurl: https://download.copr.fedorainfracloud.org/results/pgfed/shorewall/fedora-rawhide-x86_64/
    - gpgcheck: 1
    - gpgkey: https://download.copr.fedorainfracloud.org/results/pgfed/shorewall/pubkey.gpg
    - enabled: 1
{%- endif %}

# read map with shorewall rules 
{%- set map = pillar.map | default('') %}
{%- load_yaml as shorewall %}
{%- include "maps/services/shorewall/shorewall_" + map + ".yaml" ignore missing %}
default:
  install: False
{%- endload %}
{%- set shorewall = salt.grains.filter_by(shorewall, grain='id', default='default') %}

{%- if shorewall.install %}
{%- include "environment/shorewall/shorewall.sls" %}
{%- else %}
{%- include "environment/shorewall/simple_shorewall.sls" %}
{%- endif %}
{%- include "environment/shorewall/simple_shorewall6.sls" %}
