{%- import_yaml "maps/pkg_data/by_os_family.yaml" as pkg_data %}
{%- set pkg_data = salt.grains.filter_by(pkg_data) %}

install packages:
  pkg.installed:
    - pkgs:
      - {{ pkg_data.named.name }}
      - {{ pkg_data.bindutils.name }}
