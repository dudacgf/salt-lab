#
# utils.update_all - envia comando de upgrade/update para os servidores linux
#
# (c) ecgf - agosto/2021

# verifica se há pacotes a excluir do upgrade automático
{%- if grains['os_family'] == 'Debian' and pillar.upg_excludes | default(False) %}
hold:
  pkg.held:
     - pkgs: {{ excludes }}
{%- endif %}

# roda um upgrade geral
upgrades:
  pkg.uptodate:
    - refresh: True
{%- if grains['os_family'] == 'RedHat' and pillar.upg_excludes | default(False) %}
    - excludes: {{ excludes }}
{%- endif %}

# retira o hold, se houver
{%- if grains['os_family'] == 'Debian' and pillar.upg_excludes | default(False) %}
unhold:
  pkg.unheld:
    - pkgs: {{ excludes }}
{%- endif %}

# se tiver upgrades da distribuicao (kernels, etc), roda aqui
{% if grains['os_family'] == 'Debian' %}
dist-upgrades:
  cmd.run:
    - name: apt-get dist-upgrade -y
    - unless: /usr/lib/nagios/plugins/check_apt -d > /dev/null
{% endif %}

# rerun pending updates so that zabbix can update values and problems
{% if grains['os_family'] == 'RedHat' %}
LANG=C dnf -q list --updates 2> /dev/null | grep -vcE '^Available|^Last' > /var/run/zabbix/updates.txt || true : cmd.run
LANG=C dnf -q list --updates --security 2> /dev/null | grep -vcE '^Available|^Last' > /var/run/zabbix/sec_updates.txt || true : cmd.run
LANG=C needs-restarting -r > /dev/null && echo 0 || echo 1 : cmd.run
{% elif grains['os_family'] == 'Debian' %}
LANG=C apt-get -qq upgrade -s | grep -c ^Inst > /var/run/zabbix/updates.txt ||  true: cmd.run
LANG=C apt-get -qq upgrade -s | grep ^Inst | grep -c security > /var/run/zabbix/sec_updates.txt || true: cmd.run
LANG=C test -f /var/run/reboot-required && echo 1 || echo 0 : cmd.run
{% endif %}

