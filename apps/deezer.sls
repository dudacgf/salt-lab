#
### deezer.sls - install zoom on a minion

{%- if grains['os_family'] == 'Debian' %}
install deezer:
  pkg.installed:
    - sources:
      - deezer: https://github.com/aunetx/deezer-linux/releases/download/v5.30.590-1/deezer-desktop_5.30.590_amd64.deb

{%- else %}
'-- Deezer for this OS not supported yet.':
  test.nop

{%- endif %}

