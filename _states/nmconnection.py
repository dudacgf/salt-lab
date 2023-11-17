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
import salt.utils.network

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

def _pick_device(hwaddr):
    if hwaddr is None:
        # use first ethernet nic available
        comment = 'no ethernet nic available'
        for d in nmcli.device():
            if d['device_type'] == 'ethernet':
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

def _ethernet(hwaddr, options, **kwargs):
    """
    creates and configures a new ethernet connection

    """
    nmcli.set_lang('C.UTF-8')
    nmcli.disable_use_sudo()

    device = _pick_device(hwaddr)
    if device is None:
        return {'result': False, 'comment': f'no ethernet device with macaddress {hwaddr}'}

    conn = _pick_connection(device.device)

    if 'autoconnect' in kwargs:
        options['connection.autoconnect'] = 'yes' if kwargs['autoconnect'] else 'no'
    options['connection.id'] = device.device
    options['connection.interface-name'] = device.device

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
                    'comment': f'connection {conn["connection.id"]} is present and in the desired state'}
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

def present(name, con_type, hwaddr, options, **kwargs):
    """
    ensures that a NetworkManager connection is present and correctly configured. 
    The connection will be named after its interface
    
    name
        not used, just name/id of the sls state
    
    nmtype
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

    if 'test' not in kwargs:
        kwargs['test'] = __opts__.get("test", False)
    if kwargs['test']:
        ret['comment'] = 'TEST nmconnection.present'
        return ret

    # do the thing
    if con_type == 'ethernet':
        result = _ethernet(hwaddr, options, **kwargs)

    
    ret['result'] = result['result']
    if 'changes' in result and len(result['changes']) > 0:
        ret['changes'] = result['changes']
    if 'comment' in result:
        ret['comment'] = result['comment']

    return ret

def active(name, hwaddr, **kwargs):
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

    device = _pick_device(hwaddr)
    conn = _pick_connection(device.device)
    try:
        nmcli.connection.up(conn['connection.id'], wait=1)
        return {'name': name, 
                'result': True, 
                'comment': f'connection {conn["connection.id"]} is active', 
                'changes': {}}
    except Exception as e:
        return {'name': name, 
                'result': False, 
                'comment': f'error activating {conn["connection.id"]} connection: {e}',
                'changes': {}}

def inactive(name, hwaddr, **kwargs):
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

    device = _pick_device(hwaddr)
    conn = _pick_connection(device.device)
    try:
        nmcli.connection.down(conn['connection.id'], wait=1)
        return {'name': name, 
                'result': True, 
                'comment': f'connection {conn["connection.id"]} is inactive', 
                'changes': {}}
    except Exception as e:
        return {'name': name, 
                'result': False, 
                'comment': f'error deactivating {conn["connection.id"]} connection: {e}',
                'changes': {}}

