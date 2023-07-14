#
## redhat.sls - configurações específicas para servidores baseados
#               em RedHat Enterprise Linux (Rocky, CentOS etc)
#
# ecgf - Setembro/2022

## ajusta modo selinux 
{% if not salt['grains.get']('flag_selinux_mode_set', False) %}

{% set selinux_mode = salt['pillar.get']('selinux_mode', 'enforcing') %}
config selinux:
  file.replace:
    - name: /etc/selinux/config
    - pattern: '^SELINUX=.*$'
    - repl: SELINUX={{ selinux_mode }}

# ativa o setting até o próximo boot
{% if selinux_mode != 'enforcing' %}
setenforce 0:
  cmd.run
{% else %}
# vou precisar disso caso rode semanage/semodule etc
policycoreutils-python-utils:
  pkg.installed

setenforce 1:
  cmd.run
{% endif %}

# seta o flag de que já configurou selinux mode
flag_selinux_mode_set:
  grains.present:
    - value: True

{% if selinux_mode == 'disabled' %}
selinux disabled:
  test.show_notification:
    - text: "*** selinux disabled. É necessário reiniciar o servidor ***"

{% else %}
'*** selinux set to {{ selinux_mode }}':
  test.nop 

{% endif %}

{% endif %} # flag_selinux_mode_set

## ajusta dnf.conf para osmajorrelease >= 8
{% if grains['osmajorrelease'] >= 8 %}

/etc/dnf/dnf.conf:
  file.append:
    - text: 
      - 'exclude=grub2* shim* mokutil'
      - 'max_parallel_downloads=10'
      - 'fastestmirror=True'

{% endif %}

## preciso do epel-release (e repo powertools) para os plugins e o nrpe
epel-release:
  pkg.installed

enable-powertools:
  cmd.run:
    - name: crb enable

## se roda em ambiente virtual (libvirt) na estação lduda, tem repo iso disponível
{% if grains.virtual | default('none') == 'kvm' %}
/etc/yum.repos.d/rocky-iso.repo:
  file.managed:
    - source: salt://files/env/rocky-iso.repo
    - user: root
    - group: root
    - mode: 0644
{% endif %}

## se precisar de shorewall, precisa baixar e instalar os pacotes
#
{% if pillar['shorewall'] | default('none') != 'none' and grains['osmajorrelease'] >= 9 %}
baixa base:
  file.managed:
    - name: /tmp/shorewall-5.2.8-0base.noarch.rpm
    - source: https://de.shorewall.org/pub/shorewall/5.2/shorewall-5.2.8/shorewall-5.2.8-0base.noarch.rpm
    - skip_verify: true
    
baixa core:
  file.managed:
    - name: /tmp/shorewall-core-5.2.8-0base.noarch.rpm
    - source: https://de.shorewall.org/pub/shorewall/5.2/shorewall-5.2.8/shorewall-core-5.2.8-0base.noarch.rpm
    - skip_verify: true

os_specific instala shorewall:
  cmd.run:
    - name: dnf install /tmp/shorewall* -y -q

{% endif %}
