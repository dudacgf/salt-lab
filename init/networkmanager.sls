#
## network-manager.sls - instala e habilita gerenciamento de rede via Network Manager
#
#

{% if grains['os_family'] in ['RedHat', 'Debian', 'Suse'] %}
/etc/NetworkManager/NetworkManager.conf:
  file.managed:
    - contents: |
          [main]
          plugins=ifupdown,keyfile
          
          [ifupdown]
          managed=True

          [device]
          wifi.scan-rand-mac-address=no

          [keyfile]
          unmanaged-devices=*,except:type:ethernet,except:type:wifi
    - user: root
    - group: root
    - mode: 640
    - makedirs: True
{% endif %}

{% if salt.service.status('NetworkManager') %}
'-- minion {{ grains.id }}/{{ grains.os }} already has Network Manager installed': test.nop

{% elif grains['os_family'] == 'Debian' %}
network-manager:
  pkg.installed

/etc/network/interfaces:
  file.managed:
    - contents: |
          # The loopback network interface
          auto lo
          iface lo inet loopback

/etc/network/interfaces.d:
  file.directory:
    - clean: True

{% if grains['os'] == 'Ubuntu' %}
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

/etc/cloud/cloud.cfg.d/99-disable-network-config.cfg:
  file.managed:
    - user: root
    - group: root
    - makedirs: true
    - contents: |
        'network: {config: disabled}'

systemctl disable systemd-networkd.service: cmd.run

{% endif %}

{% elif grains['os_family'] == 'Suse' %}
NetworkManager: pkg.installed

wicked: service.disabled

systemctl daemon-reload: cmd.run

systemctl enable NetworkManager: cmd.run

systemctl start NetworkManager: cmd.run

{% else %}
'-- OS not supported':
  test.nop
{% endif %}
