#
## drivers.init - check for drivers in a minion's pillar e calls each driver's state file

flag_driver_installed:
  grains.present:
    - value: False

{% set drivers = pillar.get('drivers', {}) %}
{%- if drivers %}
{%- for driver in drivers %}
  {%- include 'drivers/' + driver + '.sls' ignore missing %}
  {%- include 'drivers/' + driver + '/init.sls' ignore missing %}
{%- endfor %}

reboot drivers:
  cmd.run:
    - name: /bin/bash -c 'sleep 5; shutdown -r now'
    - bg: True
    - onlyif:
        - fun: match.grain
          tgt: 'flag_driver_installed:true'

'=== no drivers installed ===':
  test.nop:
    - onlyif:
        - fun: match.grain
          tgt: 'flag_driver_installed:false'

no drivers installed send event:
  cmd.run:
    - name: /bin/bash -c "sleep 5; salt-call event.send 'salt/minion/{{ grains['id'] }}/start'"
    - bg: True
    - onlyif:
        - fun: match.grain
          tgt: 'flag_driver_installed:false'
{% else %}
no drivers to install send event:
  cmd.run:
    - name: /bin/bash -c "sleep 5; salt-call event.send 'salt/minion/{{ grains['id'] }}/start'"
    - bg: True

'== no drivers to be installed ==':
  test.nop
{% endif %}

remove flag:
  grains.absent:
    - name: flag_driver_installed
    - order: 10100
