{% if pillar.cis | default('nonenforced') == 'enforced' %}
{% include "cis-benchmark/" + grains['os'] | lower() + ".sls" ignore missing %}
{% else %}
'-- CIS recommendations will not be enforced': test.nop
{% endif %}
