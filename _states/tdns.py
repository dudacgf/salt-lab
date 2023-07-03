"""
tnds.py
=======

Configuration of a Technitium DNS Server. Manages server settings, 
zones, dhcp scopes, and zone records.

The fields accepted for management are all from TDNS' api documentation
https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md

(c) ecgf - 2023
  
Apache 2 license
https://www.apache.org/licenses/LICENSE-2.0.html

"""

import json
import urllib
import logging

from salt.utils.dictdiffer import deep_diff

log = logging.getLogger(__name__)

__virtual_name__ = 'tdns'

def __virtual__():
    """
        Checks if Technitium DNS is installed and running
    """

    if __grains__['os'] == 'Windows':
        service = 'DnsService'
    else:
        service = 'dns.service'

    if (
        __salt__['service.available'](service) and
        __salt__['service.status'](service)
       ):
        return True
    else:
        return False, "Technitium DNS not installed"

def server_configured(name, **kwargs):
    """
    manages TDNS server configuration
    
    name
        not used, just name/id of the sls state

    kwargs
        settings fields and values. for a list of fields, 
        consult the API documentation
    """

    ret = {'name': name, 
           'changes': {}, 
           'comment': 'TDNS settings are in the desired state',
           'result': True}

    if 'test' not in kwargs:
        kwargs['test'] = __opts__.get("test", False)
       
    # default server settings
    server_settings = {
        'dnsServerDomain': '',
        'dnsServerLocalEndPoints': ['0.0.0.0:53', '[::]:53'],
        'webServiceLocalAddresses': ['0.0.0.0', '[::]'],
        'webServiceHttpPort': 5380,
        'webServiceEnableTls': False,
        'webServiceTlsPort': 53443,
        'webServiceUseSelfSignedTlsCertificate': False,
        'webServiceTlsCertificatePath': '',
        'webServiceTlsCertificatePassword': '',
        'enableDnsOverHttp': False,
        'enableDnsOverTls': False,
        'enableDnsOverHttps': False,
        'dnsTlsCertificatePath': '',
        'dnsTlsCertificatePassword': '',
        'tsigKeys': False,
        'defaultRecordTtl': 3600,
        'dnsAppsEnableAutomaticUpdate': False,
        'preferIPv6': False,
        'udpPayloadSize': 1232,
        'dnssecValidation': False,
        'eDnsClientSubnet': False,
        'eDnsClientSubnetIPv4PrefixLength': 24,
        'eDnsClientSubnetIPv6PrefixLength': 56,
        'resolverRetries': 2,
        'resolverTimeout': 2000,
        'resolverMaxStackCount': 16,
        'forwarderRetries': 3,
        'forwarderTimeout': 2000,
        'forwarderConcurrency': 2,
        'clientTimeout': 4000,
        'tcpSendTimeout': 10000,
        'tcpReceiveTimeout': 10000,
        'enableLogging': True,
        'logQueries': False,
        'useLocalTime': False,
        'logFolder': 'logs',
        'maxLogFileDays': 0,
        'maxStatFileDays': 0,
        'recursion': 'AllowOnlyForPrivateNetworks',
        'recursionDeniedNetworks': [],
        'recursionAllowedNetworks': [],
        'randomizeName': True,
        'qnameMinimization': True,
        'nsRevalidation': True,
        'qpmLimitRequests': 0,
        'qpmLimitErrors': 0,
        'qpmLimitSampleMinutes': 5,
        'qpmLimitIPv4PrefixLength': 24,
        'qpmLimitIPv6PrefixLength': 56,
        'serveStale': True,
        'serveStaleTtl': 259200,
        'cacheMinimumRecordTtl': 10,
        'cacheMaximumRecordTtl': 86400,
        'cacheNegativeRecordTtl': 300,
        'cacheFailureRecordTtl': 60,
        'cachePrefetchEligibility': 2,
        'cachePrefetchTrigger': 9,
        'cachePrefetchSampleIntervalInMinutes': 5,
        'cachePrefetchSampleEligibilityHitsPerHour': 30,
        'proxyType': 'None',
        'proxyAddress': '',
        'proxyPort': '',
        'proxyUsername': '',
        'proxyPassword': '',
        'proxyBypass': '',
        'forwarders': [],
        'forwarderProtocol': 'Udp',
        'enableBlocking': True,
        'allowTxtBlockingReport': True,
        'blockingType': 'AnyAddress',
        'customBlockingAddresses': '',
        'blockListUrls': [],
        'blockListUpdateIntervalHours': 24,
    }

    # get current settings from the server
    settings = __salt__['tdns.settings']()

    # merge dictionaries preserving current settings 
    settings = {**server_settings, **settings}

    # this are not settings
    del settings['version']
    if 'blockListNextUpdatedOn' in settings:
        del settings['blockListNextUpdatedOn']
    if 'temporaryDisableBlockingTill' in settings:
        del settings['temporaryDisableBlockingTill']

    # this settings are not available yet. sorry. TODO. I swear I'll do it. 
    del settings['webServiceTlsCertificatePath']
    del settings['webServiceTlsCertificatePassword']
    del settings['dnsTlsCertificatePath']
    del settings['dnsTlsCertificatePassword']

    if 'forwarders' in settings and settings['forwarders'] is None:
        settings['forwarders'] = 'False'

    if 'proxy' in settings and settings['proxy'] is None:
        del settings['proxy']

    # check for changes
    for key in kwargs:
        if key in settings:
            if settings[key] != kwargs[key]:
                ret['changes'][key] = {'old': settings[key], 'new': kwargs[key]}
                settings[key] = kwargs[key]
        elif key != 'test':
             ret['result'] = False
             ret['comment'] = f'Illegal field: {key}'
             ret['changes'] = {}
             return ret

    if kwargs['test']:
        if len(ret['changes']) > 0:
            ret['comment'] = 'TDNS settings updated'
        ret['result'] = None
        return ret

    if len(ret['changes']) > 0:
        ret['result'], message = __salt__['tdns.settings_set'](settings)
        if not ret['result']:
           ret['comment'] = f'TDNS settings not updated: { message }'
        else:
           ret['comment'] = 'TDNS settings updated'

    return ret

def dhcpscope_managed(name, **kwargs):
    """
      manages a dhcp scope, creating e/or reconfiguring it

      name 
          scope name

      **kwargs 
         dhcp scop field list. see 
         lista de campos recebidos do sls e que correspondem aos campos da api
         ver variável scope abaixo para a lista de campos aceitos
    """

    ret = {'name': name, 'changes': {}, 'comment': '', 'result': None}

    if 'test' not in kwargs:
        kwargs['test'] = __opts__.get("test", False)

    new_scope = not __salt__['tdns.dhcpscope_exists'](name)

    enable_present = False
    if 'enable' in kwargs:
        if new_scope:
            enabled_option = kwargs['enable']
            enable_present = True
            ret['changes']['enabled'] = {'old': '', 'new': kwargs['enable']}
        elif kwargs['enable'] != __salt__['tdns.dhcpscope_enabled'](name):
            enabled_option = kwargs['enable']
            enable_present = True
            ret['changes']['enabled'] = {'old': not kwargs['enable'], 'new': kwargs['enable']}
        del kwargs['enable']

    scope_settings_options = {
        'name': name,
        'startingAddress': '',
        'endingAddress': '',
        'subnetMask': '',
        'leaseTimeDays': 1,
        'leaseTimeHours': 0,
        'leaseTimeMinutes': 0,
        'offerDelayTime': 0,
        'pingCheckEnabled': False,
        'pingCheckTimeout': 1000,
        'pingCheckRetries': 2,
        'domainName': '',
        'domainSearchList': [],
        'dnsUpdates': True,
        'dnsTtl': 900,
        'serverAddress': '',
        'serverHostName': '',
        'bootFileName': '',
        'routerAddress': '',
        'useThisDnsServer': True,
        'dnsServers': [],
        'winsServers': [],
        'ntpServers': [],
        'ntpServerDomainNames': [],
        'staticRoutes': [],
        'vendorInfo': '',
        'exclusions': [],
        'reservedLeases': False,
        'blockLocallyAdministeredMacAddresses': False,
        'allowOnlyReservedLeases': False,
        'capwapAcIpAddresses': [],
    }

    if new_scope:
        scope_options = scope_settings_options
        ret['comment'] = f'DHCP Scope \'{name}\' created'
        ret['changes'][name] = 'DHCP Scope created'
    else:
        scope_options = __salt__['tdns.dhcpscope'](name)
        # merge two dicts: https://stackoverflow.com/questions/9819602/union-of-dict-objects-in-python
        scope_options = {**scope_settings_options, **scope_options}
        ret['comment'] = f'DHCP Scope \'{name}\' is present'

    for key in kwargs:
        if key in scope_options:
            if scope_options[key] != kwargs[key]:
                ret['changes'][key] = {'old': scope_options[key], 'new': kwargs[key]}
                scope_options[key] = kwargs[key]
        elif key != 'test':
           ret['result'] = False
           ret['comment'] = f'Illegal field: {key}'
           ret['changes'] = {}
           return ret

    if new_scope and (scope_options['startingAddress'] == '' or 
        scope_options['endingAddress'] == '' or scope_options['subnetMask'] == ''):
            ret['result'] = False
            ret['comment'] = 'Cannot create a DHCP scope without startingAddress, endingAddress and subnetMask'
            ret['changes'] = {}
            return ret

    if kwargs['test']:
        ret['result'] = None
        return ret
            
    if ret['changes'] != {}:
        try:
            ret['result'], message = __salt__['tdns.dhcpscope_set'](scope_options)
            if not ret['result']:
                ret['changes'] = {}
                ret['comment'] = message
                return ret
        except Exception as exc:
            ret['changes'] = {}
            ret['result'] = False
            ret['comment'] = str(exc)
            return ret
        if not new_scope:
            if enable_present:
                ret['comment'] = ret['comment'] + ', was updated'
            else:
                ret['comment'] = ret['comment'] + ' and was updated'
    else:
        ret['comment'] = ret['comment'] + ' and in the desired state'
        ret['result'] = True

    if enable_present:
        if enabled_option:
            ret['result'], message = __salt__['tdns.dhcpscope_enable'](name)
            if ret['result']:
                ret['comment'] = ret['comment'] + ' and was enabled'
            else:
                ret['comment'] = ret['comment'] + ' but could not be enabled: ' + message
        else:
            ret['result'], message = __salt__['tdns.dhcpscope_disable'](name)
            if ret['result']:
                ret['comment'] = ret['comment'] + ' and was disabled'
            else:
                ret['comment'] = ret['comment'] + ' but could not be disabled: ' + message

    return ret

def dhcpscope_absent(name, **kwargs):
    """
      garante que um dhcp scope não existe

      name 
          nome do scope
      
    """

    ret = {'name': name, 'changes': {}, 'comment': '', 'result': True}

    if 'test' not in kwargs:
        kwargs['test'] = __opts__['test']

    exists = __salt__['tdns.dhcpscope_exists'](name)
    if exists:
        ret['changes'] = {name: 'DHCP scope deleted'} 
        ret['comment'] = f'DHCP scope \'{name}\' was deleted' 
    else:
        ret['comment'] = f'DHCP scope \'{name}\' is absent'
        
    if kwargs['test']:
        ret['result'] = None
        return ret
    
    if exists:
        ret['result'], ret['comment'] = __salt__['tdns.dhcpscope_delete'](name)
        if not ret['result']:
            ret['comment'] = f'DHCP scope \'{name}\' was not deleted: { ret["comment"] }'
            ret['changes'] = {}

    return ret

def zone_managed(name, **kwargs):
    """
       manages creation and configuration of a zone

       name
           zone's name

       kwargs
           API fields. see API documentation for a list of fields and valid values
    """

    log.info(f'Name: {name}, kwargs: {kwargs}')

    def _check_soa(new_zone, zone_name, zone_type, **soa_nr):
        # check for changes in soa record for primary and secondary zones
        rr = {'domain': zone_name, 'zone': zone_name, 'type': 'SOA'}
        soa_r = __salt__['tdns.zonerecord_clean'](**rr)
        if not soa_r['exists']:
            ret['comment'] = f"could not read SOA record: {soa_r['message']}"
            return ret
        soa_r = soa_r['record']
        soa_nr = {**soa_r, **soa_nr}
        diffs = deep_diff(soa_r, soa_nr) 
        if 'old' in diffs: # has soa updates
            for key in diffs['old']:
                if new_zone:
                    ret['changes'][key] = soa_nr[key]
                else:
                    ret['changes'][key] = {'old': soa_r[key], 'new': soa_nr[key]}
            soa_nr['overwrite'] = True
        return soa_nr

    # early inicializations
    ret = {'name': name, 'changes': {}, 'comment': '', 'result': True}

    if not 'zone' in kwargs:
       kwargs['zone'] = name

    if 'name' in kwargs:
       del kwargs['name']

    if not 'type' in kwargs:
       kwargs['type'] = 'Primary'

    if not 'test' in kwargs:
        kwargs['test'] = __opts__['test']
    
    new_zone = not __salt__['tdns.zone_exists'](kwargs['zone'])

    #
    # cannot change type of an existing zone
    if not new_zone and __salt__['tdns.zone_options'](name)['type'] != kwargs['type']:
        ret['comment'] = f'Zone \'{name}\' already exists as { kwargs["type"] }'
        ret['result'] = False
        return ret
    
    #
    # options for zone creation by type of zone
    log.info(f'type: {kwargs["type"]}')
    zcreate_options = {'zone',  'type'}
    if kwargs['type'] in {'Primary', 'Secondary'}:
        zcreate_options = zcreate_options.union({
            'zoneTransferProtocol', 'primaryNameServerAddresses', 'tsigKeyName'
        })
    if kwargs['type'] == 'Primary':
        zcreate_options = zcreate_options.union({'dnssecValidation'})
    if kwargs['type'] in {'Secondary', 'Stub'}:
        zcreate_options = zcreate_options.union({'primaryNameServerAddresses'})
    if kwargs['type'] == 'Forwarder':
        zcreate_options = zcreate_options.union({
            'forwarder', 'protocol', 'dnssecValidation', 'proxyType', 
            'proxyAddress', 'proxyPort', 'proxyUsername', 'proxyPassword',
        })    

    #
    # options for zone options update by type of zone
    zupdate_options = {'zone',  'disabled'}
    if kwargs['type'] in {'Primary', 'Secondary'}:
        zupdate_options = zupdate_options.union({
            'zoneTransfer', 'zoneTransferNameServers', 'zoneTransferTsigKeyNames',
            'notify', 'notifyNameServers'
        })
    if kwargs['type'] == 'Primary':
        zupdate_options = zupdate_options.union({
            'update', 'updateIpAddresses', 'updateSecurityPolicies'
        })
    fwd_fields = {
        'forwarder', 'protocol', 'dnssecValidation', 'proxy',
        'proxyHost', 'proxyPort', 'proxyUsername', 'proxyPassword'
    }
    soa_fields = {
        'expire', 'minimum', 'primaryNameServer', 'refresh', 'responsiblePerson', 
        'retry', 'serial'
    }
    if kwargs['type'] in ['Secondary', 'Stub']:
        soa_fields.union({'primaryNameServerAddresses'})
    all_options = zcreate_options.union(zupdate_options.union(fwd_fields.union(soa_fields)))

    #
    # populate zone, options and maybe soa and fwd records
    if new_zone:
        nzopts = {}
        zopts = {}
        ret['changes'] = {
            'zone': kwargs['zone'],
            'type': kwargs['type'],
        }
        zopts['zone'] = kwargs['zone']
    else:
        zopts = __salt__['tdns.zone_options'](kwargs['zone'])
        zopts['zone'] = zopts.pop('name')
    soa_nr = {}
    fwd_nr = {}
    dnssec_action = None

    for key in kwargs:
        if key not in all_options and key != 'test':
            ret['changes'] = {}
            ret['comment'] = f'illegal field: {key}'
            ret['result'] = False
            return ret

        # populate zone creation options
        if new_zone and key in zcreate_options:
            nzopts[key] = kwargs[key]
            ret['changes'][key] = kwargs[key]

        # populate zone update options 
        if key in zupdate_options:
            if new_zone:
                ret['changes'][key] = kwargs[key]
            elif key in zopts and kwargs[key] != zopts[key]:
                ret['changes'][key] = {'old': zopts[key], 'new': kwargs[key]}
            zopts[key] = kwargs[key]

        # populate FWD record update options
        if not new_zone and zopts['type'] == 'Forwarder' and key in fwd_fields:
            fwd_nr[key] = kwargs[key]
        else:
            log.info(f'key: {key}')

        # check if needs to sign the zone
        if key == 'dnssecValidation' and not new_zone and kwargs['type'] == 'Primary':
            if zopts['dnssecStatus'] == 'Unsigned' and kwargs['dnssecValidation']:
                ret['changes']['dnssecValidation'] = {
                   'new': 'sign',
                   'old': 'unsign',
                }
                dnssec_action = 'sign'
            elif zopts['dnssecStatus'] != 'Unsigned' and not kwargs['dnssecValidation']:
                ret['changes']['dnssecValidation'] = {
                   'new': 'unsign',
                   'old': 'sign',
                }
                dnssec_action = 'unsign'

        # populate SOA record update options
        if kwargs['type'] in ['Primary', 'Secondary'] and key in soa_fields:
            soa_nr[key] = kwargs[key]
    soa_nr['overwrite'] = True if soa_nr else False
    fwd_nr['overwrite'] = True if fwd_nr else False

    # 
    if new_zone:
        if len(ret['changes']) > 2:
            ret['comment'] = f'Zone \'{name}\' created and options applied'
        else:
            ret['comment'] = f'Zone \'{name}\' created'
    else:
        if len(ret['changes']) > 0:
            ret['comment'] = f'Zone \'{name}\' is present and options applied'
        else:
            ret['comment'] = f'Zone \'{name}\' is present and in the desired state'

    # check for changes in forwarder record
    if not new_zone and kwargs['type'] == 'Forwarder':
        rr = {'domain': zopts['zone'], 'zone': zopts['zone'], 'type': 'FWD'}
        fwd_r = __salt__['tdns.zonerecord_clean'](**rr)
        if not fwd_r['exists']:
           ret['comment'] = f"could not read FWD record: {fwd_r['message']}"
           return ret
        fwd_r = fwd_r['record']
        fwd_nr = {**fwd_r, **fwd_nr}
        diffs = deep_diff(fwd_r, fwd_nr)
        if 'old' in diffs: # has fwd updates
            for key in diffs['old']:
                fwd_nr[f"new{key.title()}"] = fwd_nr[key]
                fwd_nr[key] = fwd_r[key]
                ret['changes'][key] = {'old': fwd_r[key], 'new': fwd_nr[f"new{key.title()}"]}

    if not new_zone and kwargs['type'] in ['Primary', 'Secondary']:
        soa_nr = _check_soa(new_zone, zopts['zone'], kwargs['type'], **soa_nr)

    #
    # if testing, we return before commiting anything
    if kwargs['test']:
        ret['result'] = None
        return ret

    #
    # creates the zone
    if new_zone:
        ret['result'], comment = __salt__['tdns.zone_create'](nzopts)
        if not ret['result']:
            ret['changes'] = {}
            ret['comment'] = comment
            return ret
        elif kwargs['type'] in ['Primary', 'Secondary']:
            soa_nr = _check_soa(new_zone, zopts['zone'], kwargs['type'], **soa_nr)
            
    #
    # apply options 
    # for a new zone, ret['changes'] will contain type and zone name
    # for old zones, ret['changes'] may contain 0 or more changes
    if (new_zone and len(ret['changes']) > 2) or len(ret['changes']) > 0:
        ret['result'], comment = __salt__['tdns.zone_options_set'](zopts)
        if not ret['result']:
            if new_zone:
                ret['comment'] = (
                    f"Zone {name} created but options not applied: {comment}"
                )
                ret['changes'] = {
                    'zone': kwargs['zone'],
                    'type': kwargs['type'],
                }
            else:
                ret['comment'] = f'Options not applied: {comment}'
                ret['changes'] = {}
            return ret

    if fwd_nr['overwrite']:
        result, comment = __salt__['tdns.zonerecord_set'](**fwd_nr)
        if not result:
            ret['comment'] = (
               f'some of this options were not applied: {fwd_nr}: {comment}'
            )
            ret['result'] = result
            return ret
        
    if soa_nr['overwrite']:
        result, comment = __salt__['tdns.zonerecord_set'](**soa_nr)
        if not result:
            ret['comment'] = (
               f'some of this options were not applied: {soa_nr}: {comment}'
            )
            ret['result'] = result
            return ret

    if dnssec_action:
        result, comment = __salt__[f'tdns.zone_{dnssec_action}'](kwargs['zone'])
        if not result:
            ret['comment'] = (
                f'could not {dnssec_action} the zone: {comment}'
            )
            ret['result'] = result
            return ret

    return ret

def zone_absent(name, **kwargs):
    """
       garante que uma zona não exista

       name
           nome da zona
    """

    ret = {'name': name, 
           'changes': {name: 'Zone was removed'}, 
           'comment': f'Zone \'{name}\' was removed', 
           'result': True
    }

    if 'test' not in kwargs:
        kwargs['test'] = __opts__['test']

    if not __salt__['tdns.zone_exists'](name):
        ret['comment'] = f'Zone \'{name}\' is not present'
        ret['changes'] = {}
        ret['result'] = True
        return ret

    if kwargs['test']:
        ret['result'] = True
        return ret

    ret['result'], ret['comment'] = __salt__['tdns.zone_delete'](name)
    if not ret['result']:
        ret['comment'] = f'Zone \'{name}\' was not removed: { ret["comment"] }'

    return ret

def zonerecord_present(name, **kwargs):
    """
    garante que um registro dns esteja presente 
    """

    ret = {'name': name,
           'changes': {},
           'comment': '',
           'result': True
    }

    if 'test' not in kwargs:
        kwargs['test'] = __opts__['test']

    if 'type' not in kwargs:
        kwargs['test'] = 'A'

    if 'domain' not in kwargs:
        kwargs['domain'] = name
    domain = kwargs['domain']

    if 'zone' not in kwargs:
        kwargs['zone'] = kwargs['domain']

    if 'ttl' not in kwargs:
        kwargs['ttl'] = 3600

    rr = {}
    if kwargs['type'] in ['A', 'AAAA']:
        try:
           rr = {
               'domain': domain,
               'type': kwargs['type'],
               'ipAddress': kwargs['ipAddress'],
               'zone': kwargs['zone'],
            }
        except KeyError as k:
           ret['result'] = False
           ret['comment'] = 'Types A and AAAA resource record must define domain, type and ipAddress'
           return ret

        old_rr = __salt__['tdns.zonerecord'](**rr)
        if old_rr['exists']:
            ret['result'] = True
            ret['comment'] = (
                f"{kwargs['type']} resource record for domain {domain} "
                f"at ip {kwargs['ipAddress']} is present"
            )
            return ret
        else:
            ret['comment'] = f"{kwargs['type']} resource record created"
            ret['changes']['domain'] = {'old': '', 'new': kwargs['domain']}
            ret['changes']['type'] = {'old': '', 'new': kwargs['type']}
            ret['changes']['ipAddress'] = {'old': '', 'new': kwargs['ipAddress']}
            ret['result'] = True

    elif kwargs['type'] == 'SOA':
        rr = {
            'zone': kwargs['zone'],
            'type': 'SOA'
        }
        old_rr = __salt__['tdns.zonerecord'](**rr)
        if old_rr['exists']:
            soa_all = {
                **{'domain': domain,
                   'type': 'SOA',
                   'zone': kwargs['zone'],
                  },
                **old_rr['record']['rData']
            }
            for key in kwargs:
                if key in soa_all and kwargs[key] != soa_all[key]:
                    ret['changes'][key] = {'old': soa_all[key], 'new': kwargs[key]}
                    soa_all[key] = kwargs[key]
            if ret['changes']:
                if 'serial' not in kwargs:
                    ret['changes']['serial'] = {
                        'old': soa_all['serial'], 
                        'new': soa_all['serial'] + 1,
                    }
                    soa_all['serial'] += 1
                ret['comment'] = 'SOA resource record updated'
                rr = soa_all
                rr['overwrite'] = True
            else:
                ret['comment'] = 'SOA resource record is in the desired state'
        else:
            ret['comment'] = 'something is wrong, could not read SOA record'
            ret['result'] = False
            return ret

    elif kwargs['type'] == 'NS':
        try:
           rr = {
               'domain': domain,
               'type': 'NS',
               'nameServer': kwargs['nameServer'],
               'zone': kwargs['zone'],
           }
        except KeyError as k:
           ret['result'] = False
           ret['comment'] = 'Type NS record must define domain, type and nameServer'
           return ret

        old_rr = __salt__['tdns.zonerecord'](**rr)
        if old_rr['exists']:
            old_rr = old_rr['record']
            ret['result'] = None if kwargs['test'] else True
            ret['comment'] = (
                f"NS resource record for nameServer {kwargs['nameServer']} "
            )
            if 'glue' in kwargs:
                if 'glueRecords' in old_rr:
                    if ',' in old_rr['glueRecords']: ## more than one glue
                        old_rr['glueRecords'] = old_rr['glueRecords'].split(',')
                    else:
                        old_rr['glueRecords'] = [ old_rr['glueRecords'] ]
                    if kwargs['glue'] != old_rr['glueRecords']:
                        ret['comment'] = f"{ret['comment']} updated "
                        ret['changes']['glue'] = {'old': old_rr['glueRecords'],
                                                  'new': kwargs['glue']}
                        rr['glue'] = kwargs['glue']
                        rr['overwrite'] = True
                    else:
                        ret['comment'] = f"{ret['comment']} is in the desired state"
                else:
                    ret['comment'] = f"{ret['comment']} updated"
                    ret['changes']['glue'] = {'old': '', 'new': kwargs['glue']}
                    rr['overwrite'] = True
            else:
                ret['comment'] = f"{ret['comment']} is the desired state "
        else:
            ret['comment'] = 'NS resource record created'
            ret['changes']['domain'] = {'old': '', 'new': kwargs['domain']}
            ret['changes']['type'] = {'old': '', 'new': kwargs['type']}
            ret['changes']['nameServer'] = {'old': '', 'new': kwargs['nameServer']}
            if 'glue' in kwargs:
                ret['changes']['glue'] = {'old': '', 'new': kwargs['glue']}
            ret['result'] = True
                   
    elif kwargs['type'] == 'MX':
        try:
           rr = {
               'domain': domain,
               'type': 'MX',
               'exchange': kwargs['exchange'],
               'preference': kwargs['preference'],
               'zone': kwargs['zone'],
            }
        except KeyError as k:
           ret['result'] = False
           ret['comment'] = (
               'Type MX record must define domain, type, exchange and '
               'preference' 
            )
           return ret

        old_rr = __salt__['tdns.zonerecord'](**rr)
        if old_rr['exists']:
            ret['result'] = True
            ret['comment'] = (
                f"MX resource record exchange {kwargs['exchange']} is present"
            )
        else:
            ret['comment'] = 'MX resource record created'
            ret['changes']['domain'] = {'old': '', 'new': kwargs['domain']}
            ret['changes']['type'] = {'old': '', 'new': kwargs['type']}
            ret['changes']['exchange'] = {'old': '', 'new': kwargs['exchange']}
            ret['changes']['preference'] = {'old': '', 'new': kwargs['preference']}
            ret['result'] = True
                   
    elif kwargs['type'] == 'CNAME':
        try:
           rr = {
               'domain': domain,
               'type': 'CNAME',
               'cname': kwargs['cname'],
               'zone': kwargs['zone'],
            }
        except KeyError as k:
           ret['result'] = False
           ret['comment'] = 'Type CNAME record must define domain, type and cname '
           return ret

        old_rr = __salt__['tdns.zonerecord'](**rr)
        if old_rr['exists']:
            ret['result'] = None if kwargs['test'] else True
            ret['comment'] = (
                f"CNAME resource record for domain {domain} is present"
            )
        else:
            rr['zone'] = kwargs['zone']
            ret['comment'] = 'CNAME resource record created'
            ret['changes']['domain'] = {'old': '', 'new': kwargs['domain']}
            ret['changes']['type'] = {'old': '', 'new': kwargs['type']}
            ret['changes']['cname'] = {'old': '', 'new': kwargs['cname']}
            ret['result'] = True
                   
    else: ## TODO: other resource record types
        ret['comment'] = f"record of type '{kwargs['type']}' is not supported yet"
        ret['result'] = False
        return ret

    if kwargs['test']:
        ret['result'] = None
        return ret

    if ret['changes']: 
        ret['result'], message = __salt__['tdns.zonerecord_set'](**rr)
        if not ret['result']:
           ret['changes'] = {}
           ret['comment'] = message

    return ret

def zonerecord_absent(name, **kwargs):
    """
    ensures a resource record is not present in a zone

    name - domain name of the resource record if field domain not in kwargs

    kwargs - TDNS api fields to identify the unique record to be deleted

    """

    ret = {'name': name,
           'changes': {},
           'comment': '',
           'result': True
    }

    if not 'domain' in kwargs:
       kwargs['domain'] = name

    r = __salt__['tdns.zonerecord'](**kwargs)
    if not r['exists']:
        ret['comment'] = f"Resource record is not present"
        return ret

    result, comment = __salt__['tdns.zonerecord'](**kwargs)
    if not result:
        ret['comment'] = f"Resource record could not be deleted: {comment}"
        ret['result'] = False
        return ret

    ret['comment'] = "Resource record deleted"
    return ret


