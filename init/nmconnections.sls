#!py

def ethernet_type_nmconnection(this_net, nic):
    return [
        '[connection]',
        f'id={nic}',
        f'uuid={__salt__.cmd.run("uuid")}',
        'type=ethernet',
        'autoconnect-priority=-999',
        f'interface-name={nic}',
        f'timestamp={__salt__.cmd.run("date +%s")}',
        '',
        '[ethernet]',
        '',
        '[ipv4]',
        f'address1={this_net["ip4_address"],this_net["ip4_gateway"]}',
        f'dns={",".join(this_net["ip4_dns"])}',
        'method=manual',
        '',
        '[ipv6]',
        'addr-gen-mode=eui64',
        'method=auto',
        '',
        '[proxy]',
    ]


def hostspot_type_nmconnection(this_net, nic):
    return [
        '[connection]',
        f'id={this_net["ap_name"]}',
        f'uuid={{ __salt__.cmd.run('uuid') }}',
        'type=wifi',
        'autoconnect=true',
        f'interface-name={nic}',
        'permissions=',
        'secondaries=',
        '',
        '[wifi]',
        'hidden=false',
        f'mac-address={this_net["hwaddr"]}',
        'mac-address-blacklist=',
        'mode=ap',
        'seen-bssids=',
        f'ssid={this_net["ap_name"]}',
        '',
        '[wifi-security]',
        'group=ccmp;',
        'key-mgmt=wpa-psk',
        'pairwise=ccmp;',
        'proto=rsn;',
        f'psk={this_net["ap_psk"]}',
        '',
        '[ipv4]',
        f'address={this_net["ip4_address"]}',
        'dns-search=',
        'method=shared',
        '',
        '[ipv6]',
        'dns-search=',
        'method=auto',
        '',
def wifi_type_nmconnection(this_net, nic):
    return [
        '[connection]',
        f'id={this_net["ap_name"]',
        f'uuid={__salt__.cmd.run("uuid")}',
        'type=wifi',
        f'interface-name={nic}',
        '',
        '[wifi]',
        'mode=infrastructure',
        f'ssid={this_net["ap_name"]',
        '',
        '[wifi-security]',
        'auth-alg=open',
        'key-mgmt=wpa-psk',
        f'psk={this_net["ap_psk"]}',
        '',
        '[ipv4]',
        'method=auto',
        '',
        '[ipv6]',
        'addr-gen-mode=default',
        'method=auto',
        '',
        '[proxy]',
        '',
    ]

def run():
    config = {}

    dhcp_only = True
    wifi_used = False

#    config['only you'] = 'test.nop'

    if 'interfaces' in __pillar__:
        for network in __pillar__['interfaces']:
            this_net = __pillar__['interfaces'][network]
            if 'dhcp' in this_net and not this_net['dhcp']:
                dhcp_only = False
                if this_net['itype'] == 'bridge' or this_net['itype'] == 'network':
                    nic = __salt__.ifaces.get_iface_name(this_net['hwaddr']) 
                    if nic is None:
                        nic = network
                    config[f'{nic}.nmconnection'] = {
                        'file.managed': [
                            {'name': f'/etc/NetworkManager/system-connections/{nic}.nmconnection'},
                            {'user': 'root'},
                            {'group': 'root'},
                            {'mode': '600'},
                            {'contents': ethernet_type_nmconnection(this_net, nic)},
                        ]
                    }
                elif this_net['itype'] == 'hotspot':
                    #### create ap/hotspot-type nmconnection
                    wifi_used = True
                elif this_net['itype'] == 'wifi':
                    #### create wifi nmconnection
                    wifi_used = True


    if wifi_used and __grains['os_family'] == 'Redhat':
        config['NetworkManager-wifi'] = 'pkg.installed'
        config['restart NetworkManager'] = {
            'module.run': [
                {'service.restart': [
                    {'name': 'NetworkManager'},
                ]}
            ]
        }


    if not dhcp_only:
        config['reboot nmconnection'] = {
            'cmd.run': [
                {'name': '/bin/bash -c \'sleep 5; shutdown -r now\''},
                {'bg': True},
            ]
        }
    else:
        config['send restart event'] = {
          'event.send': [
              {'data': '-- all connections use dhcp.'},
          ]
        }

    return config
      

