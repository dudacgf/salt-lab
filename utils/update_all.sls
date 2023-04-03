#
# utils.update_all - envia comando de upgrade/update para os servidores linux
#
# (c) ecgf - agosto/2021

# roda um upgrade geral
upgrades:
  pkg.uptodate:
    - refresh: True

# se tiver upgrades da distribuicao (kernels, etc), roda aqui
{% if grains['os_family'] == 'Debian' %}
dist-upgrades:
  cmd.run:
    - name: apt-get dist-upgrade -y
    - unless: /usr/lib/nagios/plugins/check_apt -d > /dev/null
{% endif %}

