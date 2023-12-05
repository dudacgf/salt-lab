#
## network-manager.sls - instala e habilita gerenciamento de rede via Network Manager
#
#

{% if grains['os_family'] == 'RedHat' %}
restart minion:
  cmd.run:
    - name: /bin/bash -c 'sleep 5; systemctl restart salt-minion'
    - bg: True

'-- redhat and derivatives >= 8 already uses networkmanager':
  test.nop

{% elif grains['os_family'] in ['Ubuntu', 'Suse'] %}
{% if grains['os'] == 'Ubuntu' %}
network-manager:
  pkg.installed

/etc/network/interfaces:
  file.managed:
    - contents:
      - '# The loopback network interface'
      - 'auto lo'
      - 'iface lo inet loopback'

/etc/network/interfaces.d:
  file.directory:
    - clean: True

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

{% elif grains['os_family'] == 'Suse' %}
NetworkManager:
  pkg.installed

wicked:
  service.disabled

enable NetworkManager:
  service.enabled:
    - name: NetworkManager

#/etc/sysconfig/network/ifcfg-eth*:
#  file.absent

{% endif %}

/etc/NetworkManager/NetworkManager.conf:
  file.managed:
    - contents: |
          [main]
          plugins=ifupdown,keyfile
          [ifupdown]
          managed=True
          [device]
          wifi.scan-rand-mac-address=no

reboot nmcli:
  cmd.run:
    - name: /bin/bash -c 'sleep 5; shutdown -r now'
    - bg: True

{% else %}
'-- OS not supported':
  test.fail_without_changes
{% endif %}
