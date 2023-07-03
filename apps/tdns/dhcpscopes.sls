#!py

#
# use pillar 'tdns_dhcpscopes' dict values to create tdns.dhcpscope_managed states
#
def run():
    
    config = {}

    if 'tdns_dhcpscopes' not in __pillar__:
        config['nada a fazer'] = {
            'test.show_notification': [
                 {'text': '*** host pillar has no TDNS dhcp scopes defined ***'},
            ],
        }
    else:
        for d in __pillar__['tdns_dhcpscopes']:
            dhcpscope = __pillar__['tdns_dhcpscopes'][d]
            options = [{k: v} for k,v in dhcpscope.items()]
            config[dhcpscope['name']] = {
               'tdns.dhcpscope_managed': options
            }

    return config
            
