{%- import_yaml "maps/pkg_data/by_os_family.yaml" as pkg_data %}
{%- set pkg_data = salt.grains.filter_by(pkg_data) -%}
#
### virt-qemu - instala programas necessários à execução de guests virtuais num host linux
#
#

virt-manager:
  pkg.installed:
    - pkgs: ['virt-manager', {{ pkg_data.guestfs-tools.name }}]

libvirt:
  group.present:
    - addusers: [ 'duda' ]

libvirt-qemu:
  group.present:
    - addusers: [ 'duda']

'==> Needs installing libvirt-python module via salt-pip on the master':
  test.nop
