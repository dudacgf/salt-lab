##
# sslfile - certificate et all source file locations for use in state formulas
#

import logging

log = logging.getLogger(__name__)

__virtual_name__ = 'sslfile'

def __virtual__():
    '''
    sslfile - return file source location of chain, certificate and privkey of a minion
              depending whether pillar 'certbot' value is true or false
    '''
    return __virtual_name__

def get():
    '''
    returns CA and minion certificates and minion privkey {as dict} source files locations
    '''
    hostname = __grains__['id'].split('.')[0]
    location = __pillar__['location']
    domain = __pillar__[f"{location}_domain"]
    return_value = {}
    if __pillar__['certbot']:
        return_value['cert'] = f"/etc/letsencrypt/live/{hostname}.{domain}/cert.pem"
        return_value['privkey'] = f"/etc/letsencrypt/live/{hostname}.{domain}/privkey.pem"
        return_value['chain'] = f"/etc/letsencrypt/live/{hostname}.{domain}/chain.pem"
    else:
        return_value['cert'] = f"salt://files/pki/CA/{hostname}.{domain}-cert.pem"
        return_value['privkey'] = f"salt://files/pki/CA/{hostname}.{domain}-privkey.pem"
        return_value['chain'] = f"salt://files/pki/CA/chain.pem"
    return return_value

def cert():
    '''
    returns minion certificate source file location
    '''
    hostname = __grains__['id'].split('.')[0]
    location = __pillar__['location']
    domain = __pillar__[f"{location}_domain"]
    if __pillar__['certbot']:
        return f"/etc/letsencrypt/live/{hostname}.{domain}/cert.pem"
    else:
        return f"salt://files/pki/CA/{hostname}.{domain}-cert.pem"

def privkey():
    '''
    returns minion private key source file location
    '''
    hostname = __grains__['id'].split('.')[0]
    location = __pillar__['location']
    domain = __pillar__[f"{location}_domain"]
    if __pillar__['certbot']:
        return f"/etc/letsencrypt/live/{hostname}.{domain}/privkey.pem"
    else:
        return f"salt://files/pki/CA/{hostname}.{domain}-privkey.pem"

def chain():
    '''
    returns minion CA chain certificate source file location
    '''
    hostname = __grains__['id'].split('.')[0]
    location = __pillar__['location']
    domain = __pillar__[f"{location}_domain"]
    if __pillar__['certbot']:
        return f"/etc/letsencrypt/live/{hostname}.{domain}/chain.pem"
    else:
        return f"salt://files/pki/CA/chain.pem"

def fullchain():
    '''
    returns minion CA fullchain certificate source file location
    '''
    hostname = __grains__['id'].split('.')[0]
    location = __pillar__['location']
    domain = __pillar__[f"{location}_domain"]
    if __pillar__['certbot']:
        return f"/etc/letsencrypt/live/{hostname}.{domain}/fullchain.pem"
    else:
        return f"salt://files/pki/CA/{hostname}.{domain}-fullchain.pem"

