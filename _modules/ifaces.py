import logging
import re
try:
    import netifaces
    HAS_NETIFACES = True
except ImportError:
    HAS_NETIFACES = False

log = logging.getLogger(__name__)

__virtual_name__ = 'ifaces'

def __virtual__():
    '''
    Only works if netifaces is available
    '''
    if HAS_NETIFACES:
        return __virtual_name__
    else:
        return False, 'The ifaces module cannot be loaded. please install netifaces python module in the minion.'


def get():
    '''
    Gets list of netifaces, returns dict like
    { ifacename: {hwaddr: xx:xx:xx:xx:xx:xx, ipv4: xxx.xxx.xxx.xxx, ipv6: xxxx::xxxx} }

    CLI Example::

        salt minion ifaces.get

    '''
    return_value = {}
    interfaces = netifaces.interfaces()
    for interface in interfaces:
      if not interface == 'lo':
        ifaddrs = netifaces.ifaddresses(interface)
        try:
          hwaddr = ifaddrs[netifaces.AF_LINK][0]['addr']
          ipv4 = ifaddrs[netifaces.AF_INET][0]['addr']
          try:
            ipv6 = re.sub("%.*", "", ifaddrs[netifaces.AF_INET6][0]['addr'])
          except KeyError:
            ipv6 = None
          return_value[interface] = {
            'hwaddr': hwaddr,
            'ipv4': ipv4,
            'ipv6': ipv6
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
    interfaces = netifaces.interfaces()
    for interface in interfaces:
      if not interface == 'lo':
        ifaddrs = netifaces.ifaddresses(interface)
        try:
          _hwaddr = ifaddrs[netifaces.AF_LINK][0]['addr']
          if _hwaddr.lower() == hwaddr.lower():
            return interface
        except:
          pass
    return None

def get_iface_ipv4(hwaddr=None):
    '''
    Gets the ipv4 of the iface via it's hwaddr

    CLI Example::

        salt minion ifaces.get_iface_ipv4 xx:xx:xx:xx:xx:xx

    '''
    interfaces = netifaces.interfaces()
    for interface in interfaces:
      if not interface == 'lo':
        ifaddrs = netifaces.ifaddresses(interface)
        try:
          _hwaddr = ifaddrs[netifaces.AF_LINK][0]['addr']
          if _hwaddr.lower() == hwaddr.lower():
            ipv4 = ifaddrs[netifaces.AF_INET][0]['addr']
            return ipv4
        except:
          pass
    return None

def get_iface_ipv6(hwaddr=None):
    '''
    Gets the ipv4 of the iface via it's hwaddr

    CLI Example::

        salt minion ifaces.get_iface_ipv4 xx:xx:xx:xx:xx:xx

    '''
    interfaces = netifaces.interfaces()
    for interface in interfaces:
      if not interface == 'lo':
        ifaddrs = netifaces.ifaddresses(interface)
        try:
          _hwaddr = ifaddrs[netifaces.AF_LINK][0]['addr']
          if _hwaddr.lower() == hwaddr.lower():
            try:
              ipv6 = re.sub("%.*", "", ifaddrs[netifaces.AF_INET6][0]['addr'])
            except KeyError:
              ipv6 = None
            return ipv6
        except:
          pass
    return None

