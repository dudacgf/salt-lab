{#
reboot_minions:
  salt.function:
    - name: system.reboot
    - at_time: 1
    - timeout: 5
    - in_seconds: True
    - tgt: {{pillar['match']|join(',')}}
    - tgt_type: list
    - kwargs:
      - bg: true
#}
reboot_minions:
  salt.function:
    - name: cmd.run_bg
    - arg:
      - 'salt-call system.reboot 1'
    - tgt: {{pillar['match']|join(',')}}
    - tgt_type: list

wait_for_reboots:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: {{pillar['match']|join(',')}}
    - timeout: 360
    - require:
      - salt: reboot_minions
