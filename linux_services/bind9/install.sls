{%- import_yaml "maps/pkg_data/" + grains.os_family | lower + ".yaml" as pkg_data %}

install packages:
  pkg.installed:
    - pkgs:
      - {{ pkg_data.named.name }}
      - {{ pkg_data.bindutils.name }}
