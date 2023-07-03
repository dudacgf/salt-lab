#!py

#
# use pillar 'tdns_zonerecords' dict values to create tdns.zone_managed states
#
def run():
    
    config = {}

    if 'tdns_zonerecords' not in __pillar__:
        config['nada a fazer'] = {
            'test.show_notification': [
                 {'text': '*** host pillar has no TDNS zone resource records defined ***'},
            ],
        }
    else:
        for z in __pillar__['tdns_zonerecords']:
            options = [{k: v} for k,v in z.items()]
            id = (
                  f"{z['domain']}"
                  f".{salt['random.get_str'](length=8,punctuation=False,whitespace=False)}"
                 )
            config[id] = {'tdns.zonerecord_present': options}

    return config
            
