#!py

#
# use pillar 'tdns_settings' dict values to create a tdns.server_configured state
#
def run():
    
    config = {}

    if 'tdns_settings' not in __pillar__:
        config['nada a fazer'] = {
            'test.show_notification': [
                 {'text': '*** este minion não define configuração para o serviço TDNS ***'},
            ],
        }
    else:
        options = [{'dnsServerDomain': __grains__['id'].split('.')[0] 
                                      + '.' 
                                      + __pillar__['internal_domain']
                  }]
        for key in __pillar__['tdns_settings']:
            options.append({key: __pillar__['tdns_settings'][key]})
        config['server_settings'] = {
            'tdns.server_configured': options
        }

    return config
            
