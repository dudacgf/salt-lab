#
### virt-qemu - instala programas necessários à execução de guests virtuais num host linux
#
#

virt-manager:
  pkg.installed:
    - pkgs: ['virt-manager', {{ pillar['pkg_data']['guestfs-tools']['name'] }}]

libvirt:
  group.present:
    - addusers: [ 'duda' ]

libvirt-qemu:
  group.present:
    - addusers: [ 'duda']

'==> Needs installing libvirt-python module via salt-pip on the master':
  test.nop
