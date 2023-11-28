{%- if pillar['pkgs'] | default(False) %}
install extra-packages:
  pkg.installed:
    - pkgs: [ {{ pillar['pkgs'] | join(',') }} ]
{% else %}
'-- no extra packages to be installed.':
  test.nop
{% endif %}

