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

def _pick_iface(hwaddr):
    nic = None
    if hwaddr is None:
        # use first ethernet nic available
        comment = 'no ethernet nic available'
        for d in nmcli.device():
            if d['device_type'] == 'ethernet':
                nic = d
                break
    else:
        for d in nmcli.device():
            if nmcli.device.show(d.device)['GENERAL.HWADDR'] == hwaddr.upper():
                nic = d
                break
    return nic

def _nic_used(iface):
    for c in nmcli.connection():
        if nmcli.connection.show(c.name)['connection.interface-name'] == iface:
            return c.name
    return None

def _ethernet(hwaddr, options, **kwargs):
    """
    creates and configures a new ethernet connection

    """
    nmcli.set_lang('C.UTF-8')
    nmcli.disable_use_sudo()

    nic = _pick_iface(hwaddr)
    if nic is None:
        return {'result': False, 'comment': f'no ethernet device with macaddress {hwaddr}'}

    if 'autoconnect' in kwargs:
        options['connection.autoconnect'] = 'yes' if kwargs['autoconnect'] else 'no'

    changes = {}
    c_name = _nic_used(nic.device)
    if nic.state == 'connected' or c_name is not None:
        equal = True
        c = nmcli.connection.show(c_name)
        for o in options:
            if o in c and c[o] != options[o]:
                equal = False
        if equal:
            comment = f'connection {nic.device} is in the desired state'
        else:
            try:
                before = nmcli.connection.show(c_name)
                options['connection.id'] = nic.device
                nmcli.connection.modify(name=c_name, options=options)
                after = nmcli.connection.show(c_name)
                diffs = deep_diff(before, after)
                if 'old' in diffs:
                    for key in diffs['old']:
                        if key in options:
                            changes[key] = {'old': before[key], 'new': after[key]}

                comment = f'{nic.device} connection modified'
            except Exception as e:
                return {'result': False, 
                        'comment': f'error modifying {nic.device} connection: {e}'}
    else:
        try:
            nmcli.connection.add(name=nic.device, conn_type='ethernet', ifname=nic.device, 
                                 autoconnect=True, options=options)
            changes['options'] = options
            comment = f'connection {nic.device} created'
        except Exception as e:
            return {'result': False, 
                    'comment': f'error adding {nic.device} connection: {e}'}

    if 'up' in kwargs:
        nic = _pick_iface(hwaddr)
        c_name = _nic_used(nic.device)
        if nic is None:
            return {'result': False,
                    'comment': 'error picking nic after adding or modifying',
                   }
        if kwargs['up']:
            if nic.state != 'connected':
                try:
                    nmcli.connection.up(c_name, wait=1)
                    changes['connection'] = {'old': 'not connected', 'new': 'connected'}
                    comment = f'connection {nic.device} activated'
                except Exception as e:
                    return {'result': False, 
                            'comment': f'error activating {nic.connection} connection: {e}'}
        elif nic.state != 'disconneted':
                try:
                    nmcli.connection.down(c_name, wait=1)
                    changes['connection'] = {'old': 'connected', 'new': 'not connected'}
                    comment = f'connection {nic.device} deactivated'
                except Exception as e:
                    return {'result': False, 
                            'comment': f'error deactivating {nic.connection} connection: {e}'}

    return {
        'result': True, 
        'comment': comment,
        'changes': changes,
    }


def present(name, con_type, hwaddr, options, **kwargs):
    """
    ensures a NetworkManager connection is present and correctly configured. 
    The connection will be named after its interface
    
    name
        not used, just name/id of the sls state
    
    nmtype
        type of connection. Currently, only ethernet, ap-hotspot and wifi connections
        are managed.

    hwaddr
        mac address of the interface to be connected. If not set, the first available and
        compatible interface will be used.

    config
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
        ret['result'] = None
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
