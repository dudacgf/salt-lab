#!py
import nmcli
import logging
import uuid

log = logging.getLogger(__name__)

def ethernet_type_nmconnection(this_net):

    options = {}
    if 'autoconnect' in this_net:
        options['autoconnect'] = this_net['autoconnect']
    options['ipv4.addresses'] = this_net['ip4_address']
    options['ipv4.gateway'] = this_net['ip4_gateway'] if 'ip4_gateway' in this_net else ''
    options['ipv4.dns'] = this_net['ip4_dns'] if 'ip4_dns' in this_net else ''
    options['ipv4.dns-search'] = this_net['ip4_dns_search'] if 'ip4_dns_search' in this_net else ''
    options['ipv4.method'] = 'manual'

    connection = { 
        'nmconnection.present': [
            {'conn_type': "ethernet"},
            {'options': options},
        ]
    }
    hwaddr = this_net["hwaddr"] if "hwaddr" in this_net else None
    if hwaddr:
        connection['nmconnection.present'].append({'hwaddr': hwaddr})
    logging.info(connection)

    return connection

def hotspot_type_nmconnection(this_net, nic):
    connection = { 
        'nmconnection.present': [
            {'conn_type': "hostpot"},
            {'ap_name': this_net['ap_name']},
            {'ap_psk': this_net['ap_psk']},
        ]
    }
    hwaddr = this_net["hwaddr"] if "hwaddr" in this_net else None
    if hwaddr:
        connection['nmconnection.present'].append({'hwaddr': hwaddr})
    ip4_address = this_net["ip4_address"] if "ip4_address" in this_net else None
    if ip4_address:
        connection['nmconnection.present'].append({'ip4_address': ip4_address})

    logging.info(connection)

    return connection

def wifi_type_nmconnection(this_net, nic):
    connection = { 
        'nmconnection.present': [
            {'conn_type': "wifi"},
            {'ap_name': this_net['ap_name']},
            {'ap_psk': this_net['ap_psk']},
        ]
    }
    hwaddr = this_net["hwaddr"] if "hwaddr" in this_net else None
    if hwaddr:
        connection['nmconnection.present'].append({'hwaddr': hwaddr})

    logging.info(connection)

    return connection

def run():
    config = {}

    dhcp_only = True
    wifi_used = False
    require = []

    if 'interfaces' in __pillar__ and __pillar__['interfaces']:
        for network in __pillar__['interfaces']:
            this_net = __pillar__['interfaces'][network]
            log.info(f'itype: {this_net["itype"]}')

            if 'dhcp' in this_net and not this_net['dhcp']:
                dhcp_only = False
            elif this_net['itype'] == 'hotspot':
                config[f'"{this_net["ap_name"]}"'] = hotspot_type_nmconnection(this_net, nic)
                require.append({'nmconnection': f'{this_net["ap_name"]}'}) 
                wifi_used = True
            elif this_net['itype'] == 'wifi':
                config[this_net['ap_name']] = wifi_type_nmconnection(this_net, nic)
                require.append({'nmconnection': this_net["ap_name"]}) 
                wifi_used = True
            else:
                continue

            if 'hwaddr' in this_net:
                nic = __salt__.ifaces.get_iface_name(this_net['hwaddr']) 
            else:
                nic = network

            if this_net['itype'] == 'bridge' or this_net['itype'] == 'network':
                config[f'{nic}'] = ethernet_type_nmconnection(this_net)
                require.append({'nmconnection': f'{nic}'}) 

    elif 'dhcp' in __pillar__ and not __pillar__['dhcp']:
        dhcp_only = False

        # ipv4 information must be present at pillar root level (we hope)
        # this only works if we only have 1 network card
        nics = __grains__['hwaddr_interfaces'].keys() - ['lo']
        if len(nics) > 1:
            return {"-- can't set nm connections without interface information if more than one interface present": "test.nop"}
        nic = list(nics)[0]
        ctype = nmcli.device.show(nic)['GENERAL.TYPE']
        this_net = {}

        if ctype == 'ethernet' or ctype == 'bridge':
            try:
                this_net['ip4_address'] = __pillar__['ip4_address']
            except KeyError:
                return {"-- ip4 address information not present in minion pillar": "test.nop"}
            this_net['ip4_gateway'] = __pillar__['ip4_gateway'] if 'ip4_gateway' in __pillar__ else ''
            this_net['ip4_dns'] = __pillar__['ip4_dns'] if 'ip4_dns' in __pillar__ else ''
            config[f'{nic}'] = ethernet_type_nmconnection(this_net)
            require.append({'nmconnection': f'{nic}'}) 

        elif ctype == 'wifi': # probably an ap connection
            wifi_used = True
            try:
                this_net['ap_name'] = __pillar__['ap_name']
                this_net['ap_psk'] = __pillar__['ap_psk']
            except KeyError:
                return {"-- ap_name or ap_psk (password) not present in minion pillar": "test.nop"}
            config[f'{nic}'] = wifi_type_nmconnection(this_net, nic)
            require.append({'nmconnection': f'{nic}'}) 

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
                {'name': '/bin/bash -c "sleep 5; systemctl restart salt-minion"'},
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
      

