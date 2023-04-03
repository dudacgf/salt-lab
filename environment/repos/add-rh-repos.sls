## preciso do epel-release (e repo powertools) para os plugins e o nrpe
{% if grains['os_family'] == 'RedHat' %}
epel-release:
  pkg.installed

enable-powertools:
  cmd.run:
    - name: yum-config-manager --enable powertools

/etc/dnf/dnf.conf:
  file.append:
    - text: 'exclude=grub2* shim* mokutil'

update-yum:
  cmd.run:
    - name: yum update -y
{% endif %}
