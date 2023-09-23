#!/usr/bin/env python3
"""

graylog.py - Graylog REST API management via saltstack execution modules.

Implements a small part of Graylog REST API:
- server settings
- indexset basic management (create/delete/rotate)
- input basic management (create/delete)
- streams basic management (create/delete/create rules/delete rules)

All methods logs into the API using the 'admin' user. user 'admin' password
is pillar['graylog']['root_pw_sha2']

The fields accepted for management are all from Graylog REST api:
https://graylog-server-url:9000/api/api-browser/

(c) ecgf - 2023
  
Apache 2 license
https://www.apache.org/licenses/LICENSE-2.0.html

"""

import pycurl
import json
import logging
import urllib
import re

#from salt.utils.dictdiffer import deep_diff
#from salt.exceptions import CommandExecutionError

log = logging.getLogger(f'_module.{__name__}')

__virtual_name__ = 'graylog'

def __virtual__():
    """
       Checks if Graylog is installed and running
    """

    if __grains__['os'] == 'Windows':
        return False, 'graylog does not run under Windows'
    else:
        service = 'graylog-server.service'

    if (
        __salt__['service.available'](service) and
        __salt__['service.status'](service)
       ):
        return True
    else:
        return False, "Graylog not installed"

def _hostname_():
    """
    returns the hostname of this minion 
    """

    hostname = __grains__['host']
    location = __pillar__['location']
    domain = __pillar__[f'{location}_domain']

    protocol = 'https' if __pillar__['graylog']['ssl_enable'] else 'http'
    log.info(f'{protocol}://{hostname}.{domain}')
    return f'{protocol}://{hostname}.{domain}'

def _adminpw_():
    return __salt__['pillar.get']('graylog:root_pw_sha2', 'admin')

#
# request write contents callback function
class _contentCallback_:
    def __init__(self):
        self.contents = ''
    def content_callback(self, buf):
        self.contents += buf.decode()


#
# performs a Graylog REST API call via pycurl and returns the contents as json
def _call_api(api_string, api_parms = None, json_data= None):

    json_contents = {}
    t = _contentCallback_()
    url_string = f"{_hostname_()}:9000/api/{api_string}"
    if api_parms is not None:
       url_string = url_string + api_parms

    log.debug(url_string)
    callapi = pycurl.Curl()
    callapi.setopt(callapi.URL, url_string)
    callapi.setopt(callapi.USERPWD, f'admin:{_adminpw_()}')
    callapi.setopt(callapi.HTTPHEADER, 
                   ['Accept: application/json',
                    'X-Requested-By: localhost', 
                    'Content-Type: application/json'
                   ]
                  )
    callapi.setopt(callapi.SSL_VERIFYPEER, False)
    callapi.setopt(callapi.SSL_VERIFYHOST, False)
    callapi.setopt(callapi.WRITEFUNCTION, t.content_callback)

    if json_data is not None:
       post_data = json.dumps(json_data)
       callapi.setopt(callapi.POSTFIELDS, post_data)
       callapi.setopt(callapi.POST, True)

    try:
        callapi.perform()
        if callapi.getinfo(pycurl.RESPONSE_CODE) >= 400:
            json_contents = {'status': 'nok', 'errorMessage': t.contents}
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

    return json_contents
    

#####
#
## Input API Calls
#
#####

#
# list all inputs
def input_list():
    """
    List all inputs in this node
    """
    r = _call_api('system/inputs')

    return r

def input_get(input_id: str):
    """
    Get information an Input
    params:
      input_id: id of the input to be listed

    returns:
      json with information about the input
    """

    r = _call_api(f'system/inputs/{input_id}')

    return r

def input_create(name: str, port: int, itype: str, **conf_parms):
    """
    Creates an input

    params:
      name: Name of the input to be created
      itype: input type as a java class 
      port: tcp/udp port to be used
      kwargs: miscellaneous parameters. varies by input type

    returns:
      json with information about the input created
    """

    log.info(f'_p_a: {conf_parms["__pub_arg"]}')
    data = {"title": name, 
            "configuration": {"port": port, 
                              "bind_address": "0.0.0.0",
                              "expand_structured_data": False,
                              "force_rdns": False,
                              "number_worker_threads": 2,
                              "store_full_message": True,
                              "tcp_keepalive": True,
                              "timezone": __pillar__['timezone'],
                             }, 
            "global": "false",
            "type": itype,
           }
    if '__pub_arg' in conf_parms and len(conf_parms['__pub_arg']) > 0:
        pub_args = conf_parms['__pub_arg'][0]
        for key in pub_args:
            log.info(f'key: {key}')
            if key not in ['name', 'itype']:
                data["configuration"][key] = pub_args[key]

    r = _call_api('system/inputs', json_data=data)

    return input_get(r['id'])

def input_delete(to_delete: str):
    """
    Deletes an Input 
    params:
      to_delete: id or name of the input to be deleted

    returns:
      null if ok, raises error if not
    """

    # try to find the id of an Input named to_delete
    input_id = ''
    ilist = input_list()
    for i in ilist['inputs']:
        if i['title'] == to_delete:
              input_id = i['id']
    # if not found, to_delete is probably the id
    if input_id == '':
        input_id = to_delete

    t = _contentCallback_()
    url_string = f"{_hostname_()}:9000/api/system/inputs/{input_id}"

    callapi = pycurl.Curl()
    callapi.setopt(callapi.URL, url_string)
    callapi.setopt(callapi.USERPWD, f'admin:{_adminpw_()}')
    callapi.setopt(callapi.HTTPHEADER, 
                   ['Accept: application/json',
                    'X-Requested-By: localhost', 
                    'Content-Type: application/json'
                   ]
                  )
    callapi.setopt(callapi.SSL_VERIFYPEER, False)
    callapi.setopt(callapi.SSL_VERIFYHOST, False)
    callapi.setopt(callapi.WRITEFUNCTION, t.content_callback)
    callapi.setopt(callapi.CUSTOMREQUEST, "DELETE")

    try:
        callapi.perform()
        if callapi.getinfo(pycurl.RESPONSE_CODE) >= 400:
            json_contents = {'rc': callapi.getinfo(pycurl.RESPONSE_CODE), to_delete: 'not found'}
        else:
            json_contents = {'rc': callapi.getinfo(pycurl.RESPONSE_CODE), to_delete: 'deleted'}
    except Exception as exc:
        json_contents = {'errorMessage': str(exc)}

    return json_contents
