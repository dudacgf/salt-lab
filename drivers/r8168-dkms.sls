r8168-dkms:
  pkg.installed

reboot 8814au:
  cmd.run:
    - name: /bin/bash -c 'sleep 5; shutdown -r now'
    - bg: True
    - require:
      - pkg: r8168-dkms

'-- driver r8168-dkms installed. will boot now':
  test.nop:
    - require:
      - pkg: r8168-dkms

8814au send start event anyway:
  cmd.run:
    - name: /bin/bash -c "sleep 5; salt-call event.send 'salt/minion/{{ grains['id'] }}/start'"
    - bg: True
    - onfail:
      - pkg: r8168-dkms

'-- driver r8168-dkms not installed':
  test.nop:
    - onfail:
      - pkg: r8168-dkms
