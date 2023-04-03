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
    logging.info('estou aqui')
    return_value = {}
    devices = nmcli.device()
    for device in devices:
        interface = device.device
        if interface == 'lo': continue
        connection = re.sub("\(externally\)\ *", "", device.connection)
        hwaddr = nmcli.device.show(interface)['GENERAL.HWADDR']
        uuid = nmcli.connection.show(connection)['connection.uuid']
        return_value[interface] = {
          'connection': connection,
          'state': device.state,
          'hwaddr': hwaddr,
          'uuid': uuid,
        }
    return return_value

def get_uuid(iface=None):
    '''
    Gets the uuid of a connection via it's interface name

    CLI Example::

        salt minion nmconn.get_uuid eth0

    '''
    # marreta: dá um up na interface para pegar o uuid enquanto ela tenta se ativar 
    for n in nmcli.connection():
      nmcli.connection.up(n.name, wait=0)

    try:
      connection = nmcli.device.show(iface)['GENERAL.CONNECTION']
      uuid = nmcli.connection.show(connection)['connection.uuid']
      return uuid
    except:
      return False
    return None

