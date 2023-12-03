import logging
import re
log = logging.getLogger(__name__)

__virtual_name__ = 'ifaces'

def __virtual__():
    return __virtual_name__

def get():
    '''
    Gets list of netifaces, returns dict like
    { ifacename: {hwaddr: xx:xx:xx:xx:xx:xx, ipv4: xxx.xxx.xxx.xxx, ipv6: xxxx::xxxx} }

    CLI Example::

        salt minion ifaces.get

    '''
    return_value = {}
    interfaces = __grains__['hwaddr_interfaces']
    for iface in interfaces:
        try:
            return_value[iface] = {
                'hwaddr': interfaces[iface],
                'ipv4': __grains__['ip4_interfaces'][iface],
                'ipv6': __grains__['ip6_interfaces'][iface],
            }
        except:
            pass
    return return_value

def get_iface_name(hwaddr=None):
    '''
    Gets the name of the iface via it's hwaddr

    CLI Example::

        salt minion ifaces.get_iface_name xx:xx:xx:xx:xx:xx

    '''
    interfaces = __grains__['hwaddr_interfaces']
    for iface in interfaces:
        if interfaces[iface].upper() == hwaddr.upper():
            return iface
    return None

def get_iface_ipv4(hwaddr=None):
    '''
    Gets the ipv4 of the iface via it's hwaddr

    CLI Example::

        salt minion ifaces.get_iface_ipv4 xx:xx:xx:xx:xx:xx

    '''
    interfaces = __grains__['hwaddr_interfaces']
    for iface in interfaces:
        if interfaces[iface].upper() == hwaddr.upper():
            return __grains__['ip4_interfaces'][iface]
    return None

def get_iface_ipv6(hwaddr=None):
    '''
    Gets the ipv4 of the iface via it's hwaddr

    CLI Example::

        salt minion ifaces.get_iface_ipv4 xx:xx:xx:xx:xx:xx

    '''
    interfaces = __grains__['hwaddr_interfaces']
    for iface in interfaces:
        if interfaces[iface].upper() == hwaddr.upper():
            return __grains__['ip6_interfaces'][iface]
    return None
