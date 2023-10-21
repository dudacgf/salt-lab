#
## network-manager.sls - instala e habilita gerenciamento de rede via Network Manager
#
#

{% if grains['os_family'] != 'RedHat' %}

network-manager:
  pkg.installed

/etc/NetworkManager/NetworkManager.conf:
  file.managed:
    - contents: |
          [main]
          plugins=ifupdown,keyfile
          [ifupdown]
          managed=True
          [device]
          wifi.scan-rand-mac-address=no

/etc/network/interfaces:
  file.managed:
    - contents:
      - '# The loopback network interface'
      - 'auto lo'
      - 'iface lo inet loopback'

/etc/network/interfaces.d:
  file.directory:
    - clean: True

{%- if grains['os'] == 'Ubuntu' %}
/etc/netplan/:
  file.directory:
    - clean: True

/etc/netplan/00-nm-managed.yaml:
  file.managed:
    - contents:
      - 'network:'
      - '    version: 2'
      - '    renderer: NetworkManager'

netplan generate: cmd.run

netplan apply: cmd.run

{% endif %}

reboot nmcli:
  cmd.run:
    - name: /bin/bash -c 'sleep 5; shutdown -r now'
    - bg: True

{% else %}

'-- redhat and derivatives >= 8 already uses networkmanager':
  test.nop

networkmanager send start event anyway:
  cmd.run:
    - name: /bin/bash -c "sleep 5; salt-call event.send 'salt/minion/{{ grains['id'] }}/start'"
    - bg: True
{% endif %}
