#!py
import nmcli

def ethernet_type_nmconnection(this_net, nic):
    connection = [
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
    ]
    ip4_gateway = this_net['ip4_gateway'] if 'ip4_gateway' in this_net else ''
    ip4_dns = this_net['ip4_dns'] if 'ip4_dns' in this_net else ''
    connection.extend([
        f'address1={this_net["ip4_address"]},{ip4_gateway}',
        f'dns={",".join(ip4_dns)}',
        'method=manual',
        '',
        '[ipv6]',
        'addr-gen-mode=eui64',
        'method=auto',
        '',
        '[proxy]',
    ])
    return connection


def hotspot_type_nmconnection(this_net, nic):
    return [
        '[connection]',
        f'id={this_net["ap_name"]}',
        f'uuid={__salt__.cmd.run("uuid")}',
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
    ]

def wifi_type_nmconnection(this_net, nic):
    return [
        '[connection]',
        f'id={this_net["ap_name"]}',
        f'uuid={__salt__.cmd.run("uuid")}',
        'type=wifi',
        f'interface-name={nic}',
        '',
        '[wifi]',
        'mode=infrastructure',
        f'ssid={this_net["ap_name"]}',
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
    require = []

    if 'interfaces' in __pillar__:
        for network in __pillar__['interfaces']:
            this_net = __pillar__['interfaces'][network]
            if 'dhcp' in this_net and not this_net['dhcp']:
                dhcp_only = False
            else:
                continue
            nic = __salt__.ifaces.get_iface_name(this_net['hwaddr']) 
            if nic is None:
                nic = network
            if this_net['itype'] == 'bridge' or this_net['itype'] == 'network':
                config[f'{nic}.nmconnection'] = {
                    'file.managed': [
                        {'name': f'/etc/NetworkManager/system-connections/{nic}.nmconnection'},
                        {'user': 'root'},
                        {'group': 'root'},
                        {'mode': '600'},
                        {'contents': ethernet_type_nmconnection(this_net, nic)},
                    ]
                }
                require.append({'file': f'{nic}.nmconnection'}) 
            elif this_net['itype'] == 'hotspot':
                config[f'{this_net["ap_name"]}.nmconnection'] = {
                    'file.managed': [
                        {'name': f'/etc/NetworkManager/system-connections/{this_net["ap_name"]}.nmconnection'},
                        {'user': 'root'},
                        {'group': 'root'},
                        {'mode': '600'},
                        {'contents': hotspot_type_nmconnection(this_net, nic)},
                    ]
                }
                require.append({'file': f'{this_net["ap_name"]}.nmconnection'}) 
                wifi_used = True
            elif this_net['itype'] == 'wifi':
                config[f'{nic}.nmconnection'] = {
                    'file.managed': [
                        {'name': f'/etc/NetworkManager/system-connections/{nic}.nmconnection'},
                        {'user': 'root'},
                        {'group': 'root'},
                        {'mode': '600'},
                        {'contents': wifi_type_nmconnection(this_net, nic)},
                    ]
                }
                require.append({'file': f'{nic}.nmconnection'}) 
                wifi_used = True
            else:
                raise(NotImplemented, f'network type {this_net["itype"]} not implemented')
    elif 'dhcp' in __pillar__ and not __pillar__['dhcp']:
        dhcp_only = False
        # ipv4 information must be present at pillar root level (we hope)
        # this only works if we only have 1 network card
        nics = __grains__['hwaddr_interfaces'].keys() - ['lo']
        if len(nics) > 1:
            return {"-- can't set nm connections without interface information if more than one interface present": "test.nop"}
        nic = list(nics)[0]
        ctype = nmcli.device.show(nic)['GENERAL.TYPE']
        config[f'"ctype: {ctype}"'] = 'test.nop'
        this_net = {}
        if ctype == 'ethernet' or ctype == 'bridge':
            try:
                this_net['ip4_address'] = __pillar__['ip4_address']
            except KeyError:
                return {"-- ip4 address information not present in minion pillar": "test.nop"}
            this_net['ip4_gateway'] = __pillar__['ip4_gateway'] if 'ip4_gateway' in __pillar__ else ''
            this_net['ip4_dns'] = __pillar__['ip4_dns'] if 'ip4_dns' in __pillar__ else ''
            config[f'{nic}.nmconnection'] = {
                'file.managed': [
                    {'name': f'/etc/NetworkManager/system-connections/{nic}.nmconnection'},
                    {'user': 'root'},
                    {'group': 'root'},
                    {'mode': '600'},
                    {'contents': ethernet_type_nmconnection(this_net, nic)},
                ]
            }
            require.append({'file': f'{nic}.nmconnection'}) 
        elif ctype == 'wifi': # probably an ap connection
            try:
                this_net['ap_name'] = __pillar__['ap_name']
                this_net['ap_psk'] = __pillar__['ap_psk']
            except KeyError:
                return {"-- ap_name or ap_psk (password) not present in minion pillar": "test.nop"}
            config[f'{nic}.nmconnection'] = {
                'file.managed': [
                    {'name': f'/etc/NetworkManager/system-connections/{nic}.nmconnection'},
                    {'user': 'root'},
                    {'group': 'root'},
                    {'mode': '600'},
                    {'contents': wifi_type_nmconnection(this_net, nic)},
                ]
            }
            require.append({'file': f'{nic}.nmconnection'}) 
            wifi_used = True

    if wifi_used and __grains__['os_family'] == 'RedHat':
        config['NetworkManager-wifi'] = {
            'pkg.installed': [
                {'require': require},
            ]
        }
        config['restart NetworkManager'] = {
            'module.run': [
                {'service.restart': [
                    {'name': 'NetworkManager'},
                    {'require': [{'pkg': 'NetworkManager-wifi'}]},
                ]}
            ]
        }


    if not dhcp_only:
        config['reboot nmconnection'] = {
            'cmd.run': [
                {'name': '/bin/bash -c \'sleep 5; shutdown -r now\''},
                {'bg': True},
                {'require': require},
            ]
        }
        config[f'"-- nmconnections {str(require)} created'] = {
            'test.nop': [
                {'require': require},
            ]
        }
    else:
        config['send restart event'] = {
          'event.send': [
              {'data': '-- all connections use dhcp.'},
          ]
        }

    return config
      

