r8168-dkms:
  pkg.installed

r8168-dkms toggle on flag_driver_installed:
  grains.present:
    - name: flag_driver_installed
    - value: True
    - require:
      - pkg: r8168-dkms

'-- driver r8168-dkms installed. will boot now':
  test.nop:
    - require:
      - pkg: r8168-dkms

'-- driver r8168-dkms not installed':
  test.nop:
    - onfail:
      - pkg: r8168-dkms
