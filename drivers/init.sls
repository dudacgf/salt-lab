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

"-- drivers {{ drivers | join(', ') }} installed":
  test.nop:
    - onlyif:
        - fun: match.grain
          tgt: 'flag_driver_installed:true'

{% endif %}

"-- no drivers to install.":
  test.nop:
    - onlyif:
        - fun: match.grain
          tgt: 'flag_driver_installed:false'

remove flag_driver_installed:
  module.run:
    - grains.delkey:
      - key: flag_driver_installed
