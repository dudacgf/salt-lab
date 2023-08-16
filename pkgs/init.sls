{%- if pillar['pkgs'] | default(False) %}
install extra-packages:
  pkg.installed:
    - pkgs: [ {{ pillar['pkgs'] | join(',') }} ]
{% endif %}

