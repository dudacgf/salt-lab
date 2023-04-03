#
# reboot and wait - sends a reboot command to a list of minions and waits 
#                   salt-minion service start event.
#
reboot_minions:
  salt.function:
    - name: cmd.run_bg
    - arg:
      - 'salt-call system.reboot'
    - tgt: [ {{pillar['match']|join(',')}} ]
    - tgt_type: list

wait_for_reboots:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ {{pillar['match']|join(',')}} ]
    - timeout: 360
    - require:
      - salt: reboot_minions
