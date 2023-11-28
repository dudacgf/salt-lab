{% if grains['os_family'] == 'RedHat' %}
'dnf -y remove --oldinstallonly --setopt installonly_limit=2 kernel': cmd.run
{% elif grains['os_family'] == 'Debian' %}
'apt-get autoremove --purge -y': cmd.run
{% else %}
'-- OS not supported.': test.nop
{% endif %}

