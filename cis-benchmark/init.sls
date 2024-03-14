{% if pillar.cis | default('nonenforced') == 'enforced' %}
{% include "cis-benchmark/" + grains['os'] | lower() + ".sls" ignore missing %}

cis system restart at the end:
  cmd.run:
    - name: bash -c "sleep 5; shutdown -r now"
    - bg: True

{% else %}
'-- CIS recommendations will not be enforced': test.nop
{% endif %}
