#!/usr/bin/env python3
import time
import logging

import json

log = logging.getLogger(f'_module.{__name__}')

__virtual_name__ = 'mwait'

def __virtual__():
    return True

def no_sleep(minion, pings = 5):
    rc = False
    rounds = 0
    while (not rc) and (rounds < pings):
        result = __salt__.cmd.run('salt ' + minion + ' test.ping --out json')
        try:
            result = json.loads(result)
            rc = result[minion]
        except Exception as e:
            rc = False
        rounds += 1

    return rc

def sleep(minion, pings = 5, sleep = 5):
    rc = False
    rounds = 0
    while (not rc) and (rounds < pings):
        result = __salt__.cmd.run('salt ' + minion + ' test.ping --out json')
        try:
            result = json.loads(result)
            rc = result[minion]
        except Exception as e:
            rc = False
        rounds += 1
        time.sleep(sleep)

    return rc

