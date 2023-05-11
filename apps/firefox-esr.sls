{% if grains['os'] == 'Ubuntu' %}
# remove o firefox original ou o snap ou seja lá o que exista atualmente no mínion
firefox:
  pkg.removed

firefox repo:
  pkgrepo.managed:
    - ppa: mozillateam/ppa

firefox-esr:
  pkg.installed:
    - require:
      - firefox repo

{% elif grains['os'] == 'Debian' %}

firefox-esr:
  pkg.installed

{% elif grains['os_family'] == 'RedHat' %}

firefox:
  pkg.installed

{% elif grains['os_family'] == 'Windows' %}
firefox-esr_x64:
  pkg.installed

{% endif %}
