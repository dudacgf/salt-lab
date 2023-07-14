import logging
import re

log = logging.getLogger(__name__)

__virtual_name = 'lusers'

def __virtual__():
    '''
    local_users - set of functions to work with pillars values 
                  users_to_create and users_to_remove
    '''
    if __pillar__.get('users_to_create', []) is None:
      return False, 'no users defined for this host'
    else:
      return True

def sys_accounts():
    '''
    sys_accounts - return list of defined system accounts of a minion
    '''
    users_to_remove = __pillar__.get('users_to_remove', [])
    system_accounts = []
    for user in __pillar__.get('users_to_create', []):
        if user not in users_to_remove:
            p = f'users_to_create:{user}:system_account'
            sa = __salt__.pillar.get(p , 'jobim')
            if __salt__.pillar.get(p, False):
                system_accounts.append(user)

    return system_accounts
