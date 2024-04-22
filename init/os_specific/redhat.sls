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
    - text: "-- selinux disabled"

{% else %}
'-- selinux set to {{ selinux_mode }}':
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

## needs-restarting
yum-utils: pkg.installed

## if salt_version == 'Sulfur' [3006.x], 'import pycurl' or 'import ldap' raises an error
{% if salt.salt_version.equal('Sulfur') %}
python3-pip:
  pkg.installed

{% set proxy = '--proxy ' + pillar.proxy if pillar.proxy else '' %}
pip lief:
  cmd.run:
    - name: 'pip {{ proxy }} -q install lief'

md2 ldap.so.2 remove:
  cmd.script:
    - source: salt://files/scripts/3006.x-md2-remove.py
{% endif %}
