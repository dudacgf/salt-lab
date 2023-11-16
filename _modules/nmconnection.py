import logging, re
try:
    import nmcli
    HAS_NMCLI = True
except ImportError:
    HAS_NMCLI = False

log = logging.getLogger(__name__)

__virtual_name__ = 'nmconn'

def __virtual__():
    '''
    Only works if nmcli is available
    '''
    if HAS_NMCLI:
        return __virtual_name__
    else:
        return False, 'The nmcli module cannot be loaded. please install nmcli python module in the minion.'


def get():
    '''
    Gets list of connections, returns dict like
    { ifacename: {connection: name, uuid: connection.uuid, hwaddr: xx:xx:xx:xx:xx:xx} }

    CLI Example::

        salt minion nmconn.get

    '''
    nmcli.set_lang('C.UTF-8')
    logging.info('estou aqui')
    return_value = {}
    devices = nmcli.device()
    for device in devices:
        interface = device.device
        if interface == 'lo': continue
        try:
            #connection = re.sub("\(externally\)\ *", "", device.connection)
            connection = re.sub("\(.*\)\ *", "", device.connection)
            hwaddr = nmcli.device.show(interface)['GENERAL.HWADDR']
            uuid = nmcli.connection.show(connection)['connection.uuid']
            return_value[interface] = {
              'connection': connection,
              'state': device.state,
              'hwaddr': hwaddr,
              'uuid': uuid,
            }
        except:
            pass
    return return_value

def get_uuid(iface=None):
    '''
    Gets the uuid of a connection via it's interface name

    CLI Example::

        salt minion nmconn.get_uuid eth0

    '''
    nmcli.set_lang('C.UTF-8')
    # marreta: dá um up na interface para pegar o uuid enquanto ela tenta se ativar 
    for n in nmcli.connection():
      try:
          nmcli.connection.up(n.name, wait=0)
      except:
          pass

    try:
      connection = nmcli.device.show(iface)['GENERAL.CONNECTION']
      uuid = nmcli.connection.show(connection)['connection.uuid']
      return uuid
    except:
      return False
    return None

def get_cmdline(network=None):
    '''
    returns nmcli line command to set a static ip address from interface pillar values

    network: virtual network that will have its ip set as static

    returns: 
      a nmcli cmd line if everything is ok
      nothing if not
    '''

    nmcli.set_lang('C.UTF-8')
    try:
        hwaddr = __pillar__['interfaces'][network]['hwaddr']
        nic = __salt__['ifaces.get_iface_name'](hwaddr)
        connUUID = get_uuid(nic)

        addr = __pillar__['interfaces'][network]['ip4_address']
        if 'ip4_gateway' in __pillar__['interfaces'][network]:
            gateway = ' ipv4.gateway ' + __pillar__['interfaces'][network]['ip4_gateway']
        else:
            gateway = ''
        if 'ip4_dns' in __pillar__['interfaces'][network]:
            d = __pillar__['interfaces'][network]['ip4_dns']
            dns = ' ipv4.dns ' + ','.join(d)
        else:
            dns = ''

        cmdSetConIP = "nmcli con mod '" + connUUID + "' ipv4.address " + addr + gateway + dns + " ipv4.method manual" 

        return cmdSetConIP
    except Exception as e: 
        return e
