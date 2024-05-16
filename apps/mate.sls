lightdm: 
  pkg.installed
{%- if grains.os == 'Debian' %}
mate-desktop-environment:
  pkg.installed
{%- elif grains.os == 'Ubuntu' %}
ubuntu-mate-desktop:
  pkg.installed
{%- elif grains.os_family == 'RedHat' %}
"Mate Desktop":
  pkg.group_installed
{%- else %}
"-- OS {{ grains.os }} not supported for Mate install": test.nop
{%- endif %}
