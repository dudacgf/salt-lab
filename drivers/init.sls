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

{% endif %}

"/salt/minion/{{ grains['id'] }}/start":
  event.send:
    - data: "== no drivers to install =="
    - onlyif:
        - fun: match.grain
          tgt: 'flag_driver_installed:false'

remove flag_driver_installed:
  module.run:
    - grains.delkey:
      - key: flag_driver_installed
