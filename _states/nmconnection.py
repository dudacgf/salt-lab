"""
nmconnection.py
=======

Offers states to create, configure, delete, activate and deactivate 
NetworkManager connections.

(c) ecgf - 2023
  
Apache 2 license
https://www.apache.org/licenses/LICENSE-2.0.html

"""

import json
import logging

from salt.utils.dictdiffer import deep_diff

try:
    import nmcli
    HAS_NMCLI = True
except:
    HAS_NMCLI = False

log = logging.getLogger(__name__)

__virtual_name__ = 'nmconnection'

def __virtual__():
    """
    only load if nmcli is present
    """

    if (HAS_NMCLI):
        return True
    else:
        return False, "Install nmcli with salt-pip"

def mod_init(low): 
    # set utf-8 solves many problems
    nmcli.set_lang('C.UTF8')
    # if minion service not run by root this will be a problem
    nmcli.disable_use_sudo()
    log.info('mod_init run')

    return True

def _pick_device(hwaddr, conn_type: str = 'ethernet'):
    """
    returns a nmcli.Device instance of a network device identified by its hwaddr
    (if hwaddr is not defined, will return the first device with conn_type)
    hwaddr
        mac address of network device to be found
    conn_type
        connection type (ethernet, wifi etc)
    """
    ctype = 'wifi' if conn_type == 'hotspot' else conn_type
    log.info('mod_init run')
    if hwaddr is None:
        # use first ethernet nic available
        comment = f'no {ctype}-like nic available'
        for d in nmcli.device():
            if d.device_type == ctype:
                return d
    else:
        for d in nmcli.device():
            if nmcli.device.show(d.device)['GENERAL.HWADDR'] == hwaddr.upper():
                return d
    return None

def _pick_connection(iface):
    for c in nmcli.connection():
        if nmcli.connection.show(c.name)['connection.interface-name'] == iface:
            return nmcli.connection.show(c.name)
    return None

def _pick_connection_by_name(name):
    log.info(f'conn name: {name}')
    try:
        return nmcli.connection.show(name)
    except Exception:
        return None

def _check_options(ifname, options, **kwargs):

    # general options
    if 'autoconnect' in kwargs:
        options['connection.autoconnect'] = 'yes' if kwargs['autoconnect'] else 'no'
    else:
        kwargs['autoconnect'] = 'yes'
        options['connection.autoconnect'] = 'yes'
    options['connection.interface-name'] = ifname 

    # ipv4 addressing
    if 'ipv4.dns' in options and isinstance(options['ipv4.dns'], list):
        options['ipv4.dns'] = ','.join(options['ipv4.dns'])
    if 'ipv4.dns-search' in options and isinstance(options['ipv4.dns-search'], list):
        options['ipv4.dns-search'] = ','.join(options['ipv4.dns-search'])
    if 'ipv4.routes' in options and isinstance(options['ipv4.routes'], list):
        options['ipv4.routes'] = ','.join(options['ipv4.routes'])

    # connection type specific options
    if 'conn_type' in kwargs:
        if kwargs['conn_type'] == 'vpn':
            options['connection.id'] = kwargs['ap_name']
            options['vpn-type'] = kwargs['vpn-type'] if 'vpn-type' in kwargs else 'openvpn'
            if 'vpn_data' in kwargs:
                options['vpn.data'] = ''
                for v in vpn_data:
                    for k in v:
                        options['vpn.data'] += f', {k}={v[k]}'
        elif kwargs['conn_type'] == 'wifi':
            options['connection.id'] = kwargs['ap_name']
            options.update({
                'ssid': kwargs['ap_name'],
                'con-name': kwargs['ap_name'],
                '802-11-wireless-security.psk': kwargs['ap_psk'],
                '802-11-wireless-security.key-mgmt': 'wpa-psk',
                '802-11-wireless-security.auth-alg': 'open',
            })
        elif kwargs['conn_type'] == 'hotspot':
            options['connection.id'] = kwargs['ap_name']
        else:
            options['connection.id'] = ifname

def _ethernet(hwaddr, options, **kwargs):
    """
    creates and configures a new ethernet connection

    """
    device = _pick_device(hwaddr)
    if device is None:
        return {'result': False, 'comment': f'no ethernet device with macaddress {hwaddr}'}
    _check_options(device.device, options, **kwargs)

    conn = _pick_connection(device.device)

    changes = {}
    if conn is None:
        try:
            nmcli.connection.add(name=device.device, ifname=device.device, conn_type='ethernet', 
                             options=options)
            return{'result': True,
                   'comment': f'connection {device.device} created',
                   'changes': {'options': options}}
        except e:
            return{'result': False,
                   'comment': f'error creating connection {device.device}: {e}'}
    else:
        equal = True
        for o in options:
            if o in conn and conn[o] != options[o]:
                equal = False
        if equal:
            return {'result': True, 
                    'comment': f'connection {conn["connection.id"]} is in the desired state'}
        try:
            before = conn
            nmcli.connection.modify(name=conn['connection.id'], options=options)
            after = _pick_connection(device.device)
            diffs = deep_diff(before, after)
            if 'old' in diffs:
                for key in diffs['old']:
                    if key in options:
                        changes[key] = {'old': before[key], 'new': after[key]}
            return {
                'result': True, 
                'comment': f'{after["connection.id"]} connection modified',
                'changes': changes}
        except Exception as e:
            return {'result': False, 
                    'comment': f'error modifying {device.device} connection: {e}'}


def _wifi(hwaddr, options, **kwargs):
    """
    creates and configures a wifi connection
    """
    device = _pick_device(hwaddr, 'wifi')
    if device is None:
        return {'result': False, 'comment': f'no ethernet device with macaddress {hwaddr}'}
    _check_options(device.device, options, **kwargs)

    conn = _pick_connection(device.device)
    
    if conn is None:
        if 'ap_name' in kwargs and 'ap_psk' in kwargs:
            try:
                nmcli.connection.add(conn_type='wifi', 
                                     ifname=device.device, 
                                     name=kwargs['ap_name'], 
                                     autoconnect=options['connection.autoconnect'],
                                     options=options)
                return{
                    'result': True,
                    'comment': f'{kwargs["ap_name"]} connection created',
                    'changes': None if not options else options}
            except Exception as e:
                return{
                    'result': False,
                    'comment': f'could not create connection {kwargs["ap_name"]}: {e}'}
        else:
            return{
                'result': False,
                'comment': f'needs an ap name and ap password to create a wifi connection'}
    else:
        try:
            changes = {}
            before = conn
            nmcli.connection.modify(name=conn['connection.id'], options=options)
            after = _pick_connection(device.device)
            diffs = deep_diff(before, after)
            if 'old' in diffs:
                for key in diffs['old']:
                    if key in options:
                        changes[key] = {'old': before[key], 'new': after[key]}
            if changes:
                return {
                    'result': True, 
                    'comment': f'{after["connection.id"]} connection modified',
                    'changes': changes}
            else:
                return {
                    'result': True,
                    'comment': f'{after["connection.id"]} connection is in the desired state',
                    'changes': {}}
        except Exception as e:
            return {'result': False, 
                    'comment': f'error modifying {device.device} connection: {e}'}


def _hotspot(hwaddr, options, **kwargs):
    """
    creates and configures a hotspot ap-mode connection
    """
    device = _pick_device(hwaddr, 'wifi')
    if device is None:
        return {'result': False, 'comment': f'no ethernet device with macaddress {hwaddr}'}
    _check_options(device.device, options, **kwargs)

    conn = _pick_connection(device.device)
    
    if conn is None:
        if 'ap_name' in kwargs and 'ap_psk' in kwargs:
            try:
                nmcli.device.wifi_hotspot(ifname=device.device,
                                          con_name=kwargs['ap_name'],
                                          password=kwargs['ap_psk'],
                                          ssid=kwargs['ap_name'])
                if options:
                    nmcli.connection.modify(name=kwargs['ap_name'], options=options)
                return{
                    'result': True,
                    'comment': f'{kwargs["ap_name"]} connection created',
                    'changes': None if not options else options}
            except Exception as e:
                return{
                    'result': False,
                    'comment': f'could not create connection {kwargs["ap_name"]}: {e}'}
        else:
            return{
                'result': False,
                'comment': f'needs an ap name and ap password to create a hotspot connection'}
    else:
        try:
            changes = {}
            before = conn
            nmcli.connection.modify(name=conn['connection.id'], options=options)
            after = _pick_connection(device.device)
            diffs = deep_diff(before, after)
            if 'old' in diffs:
                for key in diffs['old']:
                    if key in options:
                        changes[key] = {'old': before[key], 'new': after[key]}
            if changes:
                return {
                    'result': True, 
                    'comment': f'{after["connection.id"]} connection modified',
                    'changes': changes}
            else:
                return {
                    'result': True,
                    'comment': f'{after["connection.id"]} connection is in the desired state',
                    'changes': {}}
        except Exception as e:
            return {'result': False, 
                    'comment': f'error modifying {device.device} connection: {e}'}


def present(name, conn_type=None, hwaddr=None, options=None, **kwargs):
    """
    ensures that a NetworkManager connection is present and correctly configured. 
    The connection will be named after its interface
    
    name
        not used, just name/id of the sls state
    
    conn_type
        type of connection. Currently, only ethernet, ap-hotspot and wifi connections
        are managed.

    hwaddr
        mac address of the interface to be connected. If not set, the first available and
        compatible interface will be used.

    options
        connnection configuration fields and values. for a list of fields, 
        consult the nmcli documentation
    """

    ret = {'name': name, 
           'changes': {}, 
           'comment': 'Connection is present and in the desired state',
           'result': None}

    if options is None:
        options = {}

    if 'test' not in kwargs:
        kwargs['test'] = __opts__.get("test", False)
    if kwargs['test']:
        ret['comment'] = 'TEST nmconnection.present'
        return ret

    if conn_type is None:
        conn_type = 'ethernet'
    kwargs['conn_type'] = conn_type

    # do the thing
    if conn_type == 'ethernet':
        result = _ethernet(hwaddr, options, **kwargs)
    elif conn_type == 'wifi':
        result = _wifi(hwaddr, options, **kwargs)
    else:
        result = _hotspot(hwaddr, options, **kwargs)
    
    ret['result'] = result['result']
    if 'changes' in result and len(result['changes']) > 0:
        ret['changes'] = result['changes']
    if 'comment' in result:
        ret['comment'] = result['comment']

    return ret

def active(name, hwaddr: str = None, **kwargs):
    """
    ensures that a connection is active
    """

    ret = {'name': name, 
           'changes': {}, 
           'comment': 'Connection is present and in the desired state',
           'result': None}

    if 'test' not in kwargs:
        kwargs['test'] = __opts__.get("test", False)
    if kwargs['test']:
        ret['comment'] = 'TEST nmconnection.active'
        return ret
    if hwaddr is None:
        if name is None:
            name = kwargs['id']
        conn = _pick_connection_by_name(name)
    else:
        device = _pick_device(hwaddr)
        conn = _pick_connection(device.device)

    if not conn:
        return{'name': name,
               'result': False,
               'comment': f'connection not activated - not found by name or mac address',
               'changes': {}}

    if 'GENERAL.STATE' in conn and conn['GENERAL.STATE'] == 'activated':
        log.info(f"state: {conn}")
        return{'name': name,
               'result': True,
               'comment': f'connection {conn["connection.id"]} is active', 
               'changes': {}}

    try:
        nmcli.connection.up(conn['connection.id'])
        return {'name': name, 
                'result': True, 
                'comment': f'connection {conn["connection.id"]} is active', 
                'changes': {'general.state': 'active'}}
    except Exception as e:
        return {'name': name, 
                'result': False, 
                'comment': f'error activating {conn["connection.id"]} connection: {e}',
                'changes': {}}

def inactive(name, hwaddr: str = None, **kwargs):
    """
    ensures that a connection is inactive
    """

    ret = {'name': name, 
           'changes': {}, 
           'comment': 'Connection is present and in the desired state',
           'result': None}

    if 'test' not in kwargs:
        kwargs['test'] = __opts__.get("test", False)
    if kwargs['test']:
        ret['comment'] = 'TEST nmconnection.inactive'
        return ret

    if hwaddr is None:
        if name is None:
            name = kwargs['id']
        conn = _pick_connection_by_name(name)
    else:
        device = _pick_device(hwaddr)
        conn = _pick_connection(device.device)

    if not conn:
        return{'name': name,
               'result': False,
               'comment': f'connection not deactivated - not found by name or mac address',
               'changes': {}}

    if not 'GENERAL.STATE' in conn:
        return{'name': name,
               'result': True,
               'comment': f'connection {conn["connection.id"]} is inactive', 
               'changes': {}}

    try:
        nmcli.connection.down(conn['connection.id'])
        return{'name': name, 
               'result': True, 
               'comment': f'connection {conn["connection.id"]} is inactive', 
               'changes': {'general-state': 'inactive'}}
    except Exception as e:
        return{'name': name, 
               'result': False, 
               'comment': f'error deactivating {conn["connection.id"]} connection: {e}',
               'changes': {}}

