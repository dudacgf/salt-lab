#!/usr/bin/env python3
"""

tdns.py - Technitium DNS API management via saltstack execution modules.

Implements a small part of TDNS API:
- server settings
- change user 'admin' password
- dns zone creation and management
- dhcp scopes creation and management

All methods logs into the API using the 'admin' user. Default 'admin' user password
is 'admin'. You can change 'admin' password via tdns.change_admin_password 
and tdns.py will use pillar['technitium_dns']['admin_pw'] if present.

Configuration of a Technitium DNS Server. Manages settings, users, groups, 
permissions, tsigs, zones, dhcp scopes, blocklists urls.

The fields accepted for management are all from TDNS' api:
https://github.com/TechnitiumSoftware/DnsServer/blob/master/APIDOCS.md

(c) ecgf - 2023
  
Apache 2 license
https://www.apache.org/licenses/LICENSE-2.0.html

"""

import pycurl
import json
import logging
import urllib
import re

from salt.utils.dictdiffer import deep_diff
from salt.exceptions import CommandExecutionError

log = logging.getLogger(f'_module.{__name__}')

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


#####
#
## API CALL 
#
#  handles login, request, logout and returns a json with response
#
#####

#
# returns user 'admin' password as defined in pillar['technitium']['admin_pw']
# or 'admin' if not present
def _admin_pw():
    return __salt__['pillar.get']('tdns:admin_pw', 'admin')

def _login(pw: str):
    """
    logs as admin. if can't log with {pw} it tries with 'admin', the default
    """
    t = ContentCallback()
    login = pycurl.Curl()
    url_string = f"http://127.0.0.1:5380/api/user/login?user=admin&pass={pw}"
    login.setopt(login.URL, url_string)
    login.setopt(login.WRITEFUNCTION, t.content_callback)
    login.perform()
    login.close()
    json_login = json.loads(t.contents)
    if json_login['status'] == 'ok':
      return json_login['token']
    else:
      if pw != 'admin':
        return _login('admin')
      else:
        raise CommandExecutionError(
                  f'Could not log in dns api with password: {pw}'
              )


def _logout(token: str):
    #
    # logs out 
    t = ContentCallback()
    logout = pycurl.Curl()
    url_string = 'http://127.0.0.1:5380/api/user/logout?token={token}'
    logout.setopt(logout.URL, url_string)
    logout.setopt(logout.WRITEFUNCTION, t.content_callback)
    logout.perform()
    logout.close()
    json_logout = json.loads(t.contents)
    if json_logout['status'] != 'ok':
      raise CommandExecutionError ('Error logging out of api')


#
# callback para obter a resposta do request 
class ContentCallback:
    def __init__(self):
        self.contents = ''
    def content_callback(self, buf):
        self.contents += buf.decode()


#
# performs a TDNS api call via pycurl and returns the contents as json
def _call_api(api_name, url_string):

    token = _login(_admin_pw())

    json_contents = {}
    t = ContentCallback()
    url_string = (
        f'http://127.0.0.1:5380/api/{api_name}?token={token}&{url_string}'
    )

    callapi = pycurl.Curl()
    callapi.setopt(callapi.URL, url_string)
    callapi.setopt(callapi.WRITEFUNCTION, t.content_callback)
    try:
        callapi.perform()
        if callapi.getinfo(pycurl.RESPONSE_CODE) >= 400:
            msg = re.sub(".*<title>(.*)</title>.*", "\\1", t.contents)
            json_contents = {'status': 'nok', 'errorMessage': msg}
    except Exception as exc:
        json_contents = {'status': 'nok', 'errorMessage': str(exc)}
    else:
        callapi.close()
        if not json_contents:
            try:
                json_contents = json.loads(t.contents)
            except json.decoder.JSONDecodeError as j:
                json_contents = {'status': 'nok', 
                                 'errorMessage': f'{str(j)} - {t.contents}'}

    _logout(token)

    return json_contents
    

#####
#
## miscellaneous api calls
#
#####

#
# changes user 'admin' password
def change_admin_password(new_pw, old_pw = 'admin'):
    """
       changes the admin password.
    """
    r = _call_api('user/changePassword', f'pass={new_pw}')

    if r['status'] != 'ok':
       return False, (
                      f'Error changing admin password with {token}: '
                      f'{r["errorMessage"]}'
                     )
    else:
       return True, 'Admin password changed'


def check_update():
    """
       checks if the app needs to be updated
    """
    r = _call_api('user/checkForUpdate', '')

    if r['status'] != 'ok':
        return False
    else:
        return r['response']['updateAvailable']


#####
# settings aux functions
def _normalize_list_field(list_field, separator = ','):
    if isinstance(list_field, list):
        return separator.join(list_field)
    else:
        return ''


def _normalize_listdict_field(listdict_field, fields, separator = '|'):
    if isinstance(listdict_field, list):
        result = []
        for d in listdict_field:
            result.append(separator.join(d[item] for item in fields))
        return separator.join(result)
    else:
        return ''


#####
#
## TDNS settings management
#
#####
def settings():
    """
       returns a dict with all settings of a TDNS installation
    """
    r = _call_api('settings/get', '')

    if r['status'] != 'ok':
       return f'Error gettings TDNS server settings: {r["errorMessage"]}'
    else:
       return r['response']


def tsigkeys_list():
    """
       returns a list with all TsigKeys names
    """
    r = _call_api('settings/getTsigKeyNames', '')

    if r['status'] != 'ok':
       return f'Error gettings TSIG key names: {r["errorMessage"]}'
    else:
       return r['response']['tsigKeyNames']


def settings_set(settings):
    """
       updates TDNS app configuration. See API documentation for a list of fields

       settings
           dict with list of fields to be updated

    """

    #
    # this settings are not available at the moment. or are not settings at all (version p.ex.)
    try:
        del settings['dnsTlsCertificatePath']
        del settings['webServiceTlsCertificatePath']
        del settings['webServiceTlsCertificatePassword']
        del settings['dnsTlsCertificatePassword']
        del settings['webServiceLocalAddresses']
    except:
        pass

    #
    # convert list fields to the api allowed format
    if 'forwarders' in settings:
        if isinstance(settings['forwarders'], bool):
            settings['forwarders'] = 'false'
        else:
            settings['forwarders'] = _normalize_list_field(settings['forwarders'])

    if 'recursionDeniedNetworks' in settings:
        settings['recursionDeniedNetworks'] = _normalize_list_field(settings['recursionDeniedNetworks'])

    if 'recursionAllowedNetworks' in settings:
        settings['recursionAllowedNetworks'] = _normalize_list_field(settings['recursionAllowedNetworks'])

    if 'customBlockingAddresses' in settings:
        settings['customBlockingAddresses'] = _normalize_list_field(settings['customBlockingAddresses'])

    if 'blockListUrls' in settings:
        settings['blockListUrls'] = _normalize_list_field(settings['blockListUrls'])

    if 'tsigKeys' in settings:
        settings['tsigKeys'] = _normalize_listdict_field(settings['tsigKeys'],
           [ 'keyName', 'sharedSecret', 'algorithmName' ])

    if 'dnsServerLocalEndPoints' in settings:
        settings['dnsServerLocalEndPoints'] = _normalize_list_field(settings['dnsServerLocalEndPoints'])

    if 'webServiceLocalAddresses' in settings:
        settings['webServiceLocalAddresses'] = _normalize_list_field(settings['webServiceLocalAddresses'])

    #
    # encode settings dict as a url string and calls api
    url_string = urllib.parse.urlencode(settings)
    url_string = urllib.parse.unquote(url_string)
    r = _call_api('settings/set', f'{url_string}')

    if r['status'] != 'ok':
        return False, f"{r['errorMessage']}: {url_string}"
    else:
        return True, 'TDNS settings updated'


#####
#
## zones management. 
#
#####
def zones_list():
    """
       returns a list of all authoratives zones hosted on this TDNS server
    """
    default_zones = [ 
        '1.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.0.ip6.arpa',
        '0.in-addr.arpa', 
        '127.in-addr.arpa', 
        '255.in-addr.arpa', 
        'localhost', 
        'ntp.org',
    ]

    r = _call_api('zones/list', f'')

    if r['status'] != 'ok':
        return None
    else:
        rclean = {'zones': []}
        for zone in r['response']['zones']:
          if zone['name'] not in default_zones:
             rclean['zones'].append(zone)
        return rclean


def zone_exists(name = 'ntp.org'):
    """
       checks if a zone is available
    """
    r = _call_api('zones/list', f'')

    if r['status'] != 'ok':
        return False
    else:
        # https://stackoverflow.com/questions/8653516/python-list-of-dictionaries-search
        return next((zone for zone in r['response']['zones'] if zone["name"] == name), None) != None


def zone_options(name):
    """
       return zone options as a json dict
    """
    r = _call_api('zones/options/get', f'zone={name}')

    if r['status'] != 'ok':
        return False
    else:
        return r['response']


def zone_enable(name):
    """
       enables a zone
    """
    r = _call_api('zones/enable', f'zone={name}')

    if r['status'] != 'ok':
        return False, f'could not enable zone {name}: {r["errorMessage"]}'
    else:
        return True, f'Zone {name} is enabled'


def zone_disable(name):
    """
       disables a zone
    """
    r = _call_api('zones/disable', f'zone={name}')

    if r['status'] != 'ok':
        return False, f'could not disable zone {name}: {r["errorMessage"]}'
    else:
        return True, f'Zone {name} is disabled'


def zone_sign(name):
    """
       signs a primary zone (DNSSEC)
    """

    url_string = f'zone={name}&algorithm=ECDSA&&&curve=P256&nxProof=NSEC3'
    r = _call_api('zone/dnssec/sign', url_string)

    if r['status'] != 'ok':
         return False, f'could not sign zone: {r["errorMessage"]}'
    else: 
         return True, 'zone signed with DNSSEC'


def zone_unsign(name):
    """
       signs a primary zone (DNSSEC)
    """

    url_string = f'zone={name}'
    r = _call_api('zone/dnssec/unsign', url_string)

    if r['status'] != 'ok':
         return False, f'could not unsign zone: {r["errorMessage"]}'
    else: 
         return True, 'zone unsigned'


def zone_options_set(zone_options):
    """
       manages options for an authoritative zone
    """

    if 'zoneTransferNameServers' in zone_options:
        if zone_options['zoneTransferNameServers'] != []:
            zone_options['zoneTransferNameServers'] = ','.join(zone_options['zoneTransferNameServers'])
        else:
            zone_options['zoneTransferNameServers'] = ''

    if 'zoneTransferTsigKeyNames' in zone_options:
        if zone_options['zoneTransferTsigKeyNames'] != []:
            zone_options['zoneTransferTsigKeyNames'] = ','.join(zone_options['zoneTransferTsigKeyNames'])
        else:
            zone_options['zoneTransferTsigKeyNames'] = ''

    if 'notifyNameServers' in zone_options:
        if zone_options['notifyNameServers'] != []:
            zone_options['notifyNameServers'] = ','.join(zone_options['notifyNameServers'])
        else:
            zone_options['notifyNameServers'] = ''

    if 'updateIpAddresses' in zone_options:
        if zone_options['updateIpAddresses'] != []:
            zone_options['updateIpAddresses'] = ','.join(zone_options['updateIpAddresses'])
        else:
            zone_options['updateIpAddresses'] = ''

    if 'updateSecurityPolicies' in zone_options:
        updateSecurityPolicies = []
        for u in zone_options['updateSecurityPolicies']:
            updateSecurityPolicies.append(f"{u['tsigKeyName']}|{u['domain']}|{','.join(u['allowedTypes'])}")
        if updateSecurityPolicies != []:
            zone_options['updateSecurityPolicies'] = '|'.join(updateSecurityPolicies)
        else:
            zone_options['updateSecurityPolicies'] = ''

    url_string = urllib.parse.urlencode(zone_options)
    url_string = urllib.parse.unquote(url_string)
    r = _call_api('zones/options/set', url_string)

    if r['status'] != 'ok':
        return False, f'could not modify zone \'{zone_options["zone"]}\': {r["errorMessage"]}'
    else:
        return True, f'zone \'{zone_options["zone"]}\' options updated'


def zone_create(zone_settings):
    """
       creates a zone.
    """

    # if called by command line
    if isinstance(zone_settings, str):
        zone_settings = json.loads(zone_settings)

    if 'primaryNameServerAddresses' in zone_settings:
        if zone_settings['primaryNameServerAddresses'] != []:
            zone_settings['primaryNameServerAddresses'] = ','.join(zone_settings['primaryNameServerAddresses'])
        else:
            zone_settings['primaryNameServerAddresses'] = ''

    url_string = urllib.parse.urlencode(zone_settings)
    url_string = urllib.parse.unquote(url_string)
    r = _call_api('zones/create', url_string)

    if r['status'] != 'ok':
        return False, f'could not create zone {zone_settings["zone"]}: {r["errorMessage"]}'
    else:
        comment = f'Zone {zone_settings["zone"]} created'

    # create dnssec if asked
    if 'dnssecValidation' in zone_settings and zone_settings['dnssecValidation']:
        rc, dummy = zone_sign(zone_settings['zone'])
        comment = comment + ' ' + dummy
        if not rc:
            return rc, comment

    return True, comment


def zone_delete(name):
    """
       deletes a zone
    """
 
    if zone_exists(name):
        r = _call_api('zones/delete', f'zone={name}')
        if r['status'] != 'ok':
            return False, r["errorMessage"]
        else:
            return True, f'Removed zone {name}'
    else:
        return True, ''


#####
#
### DNS Records management
#
####
def zonerecords_list(**kwargs):
    """
    return a list of all records in a zone

    domain - name of domain 

    **kwargs: record fields. e.g.
        type: record type
        ipAddress: A or AAAA ip address for type 'A' or 'AAAA' records
        nameServer: name server domain name for type 'NS' records
        exchange: exchange domain name for type 'MX' records
        preference: preference for type 'MX' records
        [... anything that can identify an unique zone record ...]

    returns:
        dict with keys 'exists' and 'message' and the following values:
            False - no such zone exists
            False - no such zone record exists
            True - zone_records in json/dict format
    """
    if '__pub_arg' in kwargs and len(kwargs['__pub_arg']) > 0:
        kwargs = kwargs['__pub_arg'][0]
    if not kwargs: 
        return {'exists': False, 'message': 'Use one or more fields to search'}

    try:
       zone = kwargs['zone']
    except KeyError:
       return {'exists': False, 'message': "Missing 'zone' field"}

    if 'domain' not in kwargs:
       domain = kwargs['zone']

    if zone_exists(kwargs['zone']):
        r = _call_api('zones/records/get', f'domain={zone}')
        if r['status'] != 'ok':
            return {'exists': False, 'message': r['errorMessage']}
        elif len(kwargs) ==  1: # only domain passed, all records
            records = r['response']['records']
        else:
            records = []
            del kwargs['zone']
            for rec in r['response']['records']:
                r_all = {**rec, **rec['rData']}
                r_all['domain'] = r_all.pop('name')
                if 'old' not in deep_diff(kwargs, r_all):
                    rec['domain'] = rec.pop('name')
                    rec['zone'] = zone
                    records.append(rec)
            if not records:
                return {'exists': False, 'message': 'Zone record not found'}
    else:
        return {'exists': False, 'message': f"zone '{kwargs['zone']}' not found"}

    return {'exists': True, 'records': records}


def zonerecord(**kwargs):
    """
    returns a record of a zone

    **kwargs: record fields. e.g.
        zone: zones name (required)
        domain: domain name (if ommitted, zone)
        ipAddress: A or AAAA ip address for type 'A' or 'AAAA' records
        nameServer: name server domain name for type 'NS' records
        exchange: exchange domain name for type 'MX' records
        preference: preference for type 'MX' records
        [... anything that can identify an unique zone record ...]

    returns:
        dict with keys 'exists' and 'message' and the following values:
            False - Use one or more fields to search
            False - no such zone exists
            False - no such zone record exists
            False - too many zone records returned
            True - zone_record in json/dict format
    """
    if '__pub_arg' in kwargs and len(kwargs['__pub_arg']) > 0:
        kwargs = kwargs['__pub_arg'][0]
    if not kwargs: 
        return {'exists': False, 'message': 'Use one or more fields to search'}

    try:
       zone = kwargs['zone']
    except KeyError:
       return {'exists': False, 'message': "Missing 'zone' field"}

    if 'domain' not in kwargs:
        kwargs['domain'] = kwargs['zone']

    if zone_exists(kwargs['zone']):
        r = _call_api('zones/records/get', f'domain={zone}')
        if r['status'] != 'ok':
            return {'exists': False, message: r['errorMessage']}
        else:
            records = []
            del kwargs['zone']
            for rec in r['response']['records']:
                r_all = {**rec, **rec['rData']}
                r_all['domain'] = r_all.pop('name')
                if 'old' not in deep_diff(kwargs, r_all):
                    rec['domain'] = rec.pop('name')
                    records.append(rec)
            if not records:
                return {'exists': False, 'message': 'Zone record not found'}
            elif len(records) > 1:
                return {'exists': False, 'message': 'Too many zone records returned'}
    else:
        return {'exists': False, 'message': f"zone '{kwargs['zone']}' not found"}

    return {'exists': True, 'record': records[0]}


def zonerecord_clean(**kwargs):
    """
    returns a record of a zone with rData merged into main dict and
    rData, dnssecStatus, and lastUsedOn fields removed (i hate oxford commas)

    **kwargs: record fields. e.g.
        zone: zones name (required)
        domain: domain name (if ommitted, zone)
        ipAddress: A or AAAA ip address for type 'A' or 'AAAA' records
        nameServer: name server domain name for type 'NS' records
        exchange: exchange domain name for type 'MX' records
        preference: preference for type 'MX' records
        [... anything that can identify an unique zone record ...]

    returns:
        dict with keys 'exists' and 'message' and the following values:
            False - Use one or more fields to search
            False - no such zone exists
            False - no such zone record exists
            False - too many zone records returned
            True - zone_record in json/dict format
    """
    r = zonerecord(**kwargs)
    if not r['exists']:
        return r

    r = {**r['record'], **r['record']['rData']}
    del r['rData']
    del r['dnssecStatus']
    del r['lastUsedOn']

    return {'exists': True, 'record': r}


def zonerecord_set(**kwargs):
    """
    adds or updates a dns record in an authoritative zone
    """
    url_string = urllib.parse.urlencode(kwargs)

    if '__pub_arg' in kwargs and (kwargs['_pub_arg']) > 0: # foi chamado da linha de comando
       kwargs = kwargs['__pub_arg'][1]
    if not kwargs: 
        return False, 'Use one or more fields to create a rrecord'

    try:
       domain = kwargs['domain']
    except KeyError:
       return False, "Missing 'domain' field"

    if 'glue' in kwargs:
       kwargs['glue'] = ','.join(kwargs['glue'])

    if 'zone' not in kwargs:
        kwargs['zone'] = domain

    if zone_exists(kwargs['zone']):
        if kwargs['type'] == 'SOA':
           api_path = 'zones/records/update'
        elif 'overwrite' in kwargs:
           api_path = 'zones/records/update'
           del kwargs['overwrite']
        else:
           api_path = 'zones/records/add'
        r = _call_api(api_path, url_string)
        if r['status'] != 'ok':
            return False, r['errorMessage']
        else:
            return True, 'record created or updated'
    else:
        return False, f"Zone '{kwargs['zone']}' does not exists"


def zonerecord_delete(**kwargs):
    """
        removes a dns record in an authoritative zone
    """
    log.info(f"[1] {kwargs}")

    if '__pub_arg' in kwargs and len(kwargs['__pub_arg']) > 0: # foi chamado da linha de comando
       kwargs = kwargs['__pub_arg'][0]
    log.info(f"[2] {kwargs}")

    url_string = urllib.parse.urlencode(kwargs)
    r = _call_api('zones/records/delete', url_string)
    if r['status'] != 'ok':
        return False, r['errorMessage']

    return True, 'Resource record removed'


#####
#
### DHCP scopes management. 
#
#####
def dhcpscopes_list():
    """
        returns a list of json formatted dhcp scopes 
    """

    r = _call_api('dhcp/scopes/list', f'')
    
    if r['status'] != 'ok':
        return False
    else:
        return r['response']


def dhcpscope(name = 'Default'):
    """
        returns a dhcp scope as json
    """
    r = _call_api('dhcp/scopes/get', f'name={name}')

    if r['status'] != 'ok':
        return False
    else:
        return r['response']


def dhcpscope_exists(name = 'Default'):
    """
       checks if a dhcp scope is available in a TDNS installation
    """
    r = _call_api('dhcp/scopes/list', f'')

    if r['status'] != 'ok':
        return False
    else:
        # https://stackoverflow.com/questions/8653516/python-list-of-dictionaries-search
        return next((s for s in r['response']['scopes'] if s["name"] == name), None) != None


def dhcpscope_enable(name):
    """
       enables a dhcp scope
    """
    r = _call_api('dhcp/scopes/enable', f'name={name}')
    
    if r['status'] != 'ok':
        return False, r['errorMessage']
    else:
        return True, ''


def dhcpscope_disable(name):
    """
       disables a dhcp scope
    """
    r = _call_api('dhcp/scopes/disable', f'name={name}')
    
    if r['status'] != 'ok':
        return False, r['errorMessage']
    else:
        return True, ''


def dhcpscope_enabled(name = 'Default'):
    """
       checks if a dhcp scope is enabled
    """
    r = dhcpscopes_list()
    scope = next((s for s in r['scopes'] if s["name"] == name), None)
    if scope != None:
        return bool(scope['enabled'])
    else:
        return False


def dhcpscope_set(scope):
    """
        creates or updates a dhcp scope. see API documentation to a list of fields

        scope
            dict with list of fields to create or update the scope
    """

    #
    # convert list fields to the api allowed format

    if 'dnsServers' in scope:
        if scope['dnsServers'] != []:
            scope['dnsServers'] = ','.join(scope['dnsServers'])
        else:
            scope['dnsServers'] = ''

    if 'winsServers' in scope:
        if scope['winsServers'] != []:
            scope['winsServers'] = ','.join(scope['winsServers'])
        else:
            scope['winsServers'] = ''

    if 'reservedLeases' in scope:
        if scope['reservedLeases'] != []:
            reservedLeases = []
            for l in scope['reservedLeases']:
                if not 'comments' in l:
                    l['comments'] = ' '
                reservedLeases.append(f"{l['hostName']}|{l['hardwareAddress']}|" + 
                                      f"{l['address']}|{l['comments']}")
            scope['reservedLeases'] = '|'.join(reservedLeases)
        else:
            scope['reservedLeases'] = ''

    if 'exclusions' in scope:
        if scope['exclusions'] != []:
           exclusions = []
           for e in scope['exclusions']:
               exclusions.append(f"{e['startingAddress']}|{e['endingAddress']}")
           scope['exclusions'] = '|'.join(exclusions)
        else:
           scope['exclusions'] = ''

    if 'staticRoutes' in scope:
        if scope['staticRoutes'] != []:
            staticRoutes = []
            for r in scope['staticRoutes']:
                staticRoutes.append(f"{r['destination']}|{r['subnetMask']}|{r['router']}")
            scope['staticRoutes'] = '|'.join(staticRoutes)
        else:
            scope['staticRoutes'] = ''

    if 'capwapAcIpAddresses' in scope:
        if scope['capwapAcIpAddresses'] != []:
            scope['capwapAcIpAddresses'] = ','.join(scope['capwapAcIpAddresses'])
        else:
            scope['capwapAcIpAddresses'] = ''

    if 'domainSearchList' in scope:
        if scope['domainSearchList'] != []:
            scope['domainSearchList'] = ','.join(scope['domainSearchList'])
        else:
            scope['domainSearchList'] = ''

    if 'ntpServerDomainNames' in scope:
        if scope['ntpServerDomainNames'] != []:
            scope['ntpServerDomainNames'] = ','.join(scope['ntpServerDomainNames'])
        else:
            scope['ntpServerDomainNames'] = ''

    if 'ntpServers' in scope:
        if scope['ntpServers'] != []:
            scope['ntpServers'] = ','.join(scope['ntpServers'])
        else:
            scope['ntpServers'] = ''
    
    if 'vendorInfo' in scope:
        if scope['vendorInfo'] != []:
            vendorInfo = []
            for v in scope['vendorInfo']:
                vendorInfo.append(f'{v["identifier"]}|{v["information"]}')
            scope['vendorInfo'] = '|'.join(vendorInfo)
        else:
            scope['vendorInfo'] = ''
               
    #
    # encode scope dict as a url string and calls api
    url_string = urllib.parse.urlencode(scope)
    url_string = urllib.parse.unquote(url_string)
    r = _call_api('dhcp/scopes/set', f'{url_string}')

    if r['status'] != 'ok':
        return False, r['errorMessage']
    else:
        return True, ''


def dhcpscope_delete(name):
    """
       deletes a dhcp scope
    """
    r = dhcpscopes_list()
    if r == []:
       return True, f'DHCP scope \'{name}\' is absent'

    scope = next((s for s in r['scopes'] if s["name"] == name), None)
    if scope != None:
        r = _call_api('dhcp/scopes/delete', f'name={name}')
        if r['status'] != 'ok':
            return False, r['errorMessage']
    else:
        return True, f'DHCP scope \'{name}\' is absent'


    return True, f'DHCP scope \'{name}\' was deleted'

