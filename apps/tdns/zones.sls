#!py

#
# use pillar 'tdns_zones' dict values to create tdns.zone_managed states
#
def run():
    
    config = {}

    if 'tdns_zones' not in __pillar__:
        config['nada a fazer'] = {
            'test.show_notification': [
                 {'text': '*** host pillar has no TDNS zones settings ***'},
            ],
        }
    else:
        for z in __pillar__['tdns_zones']:
            zone = __pillar__['tdns_zones'][z]
            options = [{k: v} for k,v in zone.items()]
            config[zone['name']] = {
               'tdns.zone_managed': options
            }

    return config
            
