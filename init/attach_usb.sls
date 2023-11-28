#!jinja|yaml

{% if pillar['usb_devices'] is defined and
      pillar['usb_devices']['attach'] | default(False) %}

{% do pillar['usb_devices'].pop('attach') %}
{% for device in pillar['usb_devices'] | default([]) %}
{% set vendor = pillar['usb_devices'][device]['vendor'] %}
{% set product_id = pillar['usb_devices'][device]['product_id'] %}
'/tmp/{{ device }}.xml':
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - template: jinja
    - contents: |
          <hostdev mode='subsystem' type='usb' managed='yes'>
            <source startupPolicy='optional'>
              <vendor id='0x{{ vendor }}' />
              <product id='0x{{ product_id }}' />
            </source>
          </hostdev>

"virsh attach-device {{ pillar['minion'] }} /tmp/{{ device }}.xml --persistent": cmd.run

{% endfor %}

{% else %}
'-- no usb devices to attach':
   test.nop
{% endif %}
