## rerun pending updates so that zabbix can update values and problems
##
## (c) ecgf - apr.2024

{% if grains['os_family'] == 'RedHat' %}
LANG=C dnf -q list --updates 2> /dev/null | grep -vcE '^Available|^Last' > /var/run/zabbix/updates.txt || true : cmd.run
LANG=C dnf -q list --updates --security 2> /dev/null | grep -vcE '^Available|^Last' > /var/run/zabbix/sec_updates.txt || true : cmd.run
{% elif grains['os_family'] == 'Debian' %}
LANG=C apt-get -qq upgrade -s | grep -c ^Inst > /var/run/zabbix/updates.txt ||  true: cmd.run
LANG=C apt-get -qq upgrade -s | grep ^Inst | grep -c security > /var/run/zabbix/sec_updates.txt || true: cmd.run
{% endif %}

