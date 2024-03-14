###
## Creates vms from a list in a import yaml map, initializes them and runs its first highstate 
#
#  You should call this as a orchestration:
#
#  sudo salt-run state.orch init [ pillar='{map: map_name}' ]
# 
#  where map_name is the name of a yaml file formed as 'maps/' + map_name + '.yaml' that 
#  contains minion information (names, profiles, interfaces etc). default: lab_minions
#
#  (c) ecgf - dec/2023
#

# get list of minions from map
{% set map = pillar.map | default('production') %}
{% import_yaml 'maps/' + map + '.yaml' as minions %}

#
### loop through list of minions creating and configuring each one
{% do minions.pop('default', None) %}
{% for mname in minions | default([]) %}
{% set minion = minions[mname] %}

### if vm does not exists yet, create and configure it
{% if mname not in salt.virt.list_domains(connection = pillar['virt']['connection']['url']) %}

{{ mname }} create_instance:
  salt.runner:
    - name: cloud.profile
    - provider: {{ minion.virtual_provider }}
    - prof: {{ minion.profile | default('debian_gold') }}
    - instances: {{ mname }}
    - opts:
      - clone_stratety: full
    - quiet: true


### attach usb devices, if any
{{ mname }} attach usb devices:
  salt.state:
    - sls: init.attach_usb
    - tgt: {{ minion.virtual_host | default(grains['id']) }}
    - pillar: {'minion': {{ mname }}, 'usb_devices': {{ minion.usb_devices | default(None) }}}

### redefines interfaces, if needed
{{ mname }} redefine interfaces:
  salt.state:
    - sls: init.redefine_interfaces
    - tgt: {{ minion.virtual_host | default(grains['id']) }}
    - pillar: {'minion': {{ mname }}, 'redefine_interfaces': {{ minion.redefine_interfaces | default(False) }}, 'minion_interfaces': {{ minion.interfaces | default({}) }} }

# wait (add minion interfaces reboots minion)
{{ mname }} wait interfaces:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ "{{ mname }}" ]
    - timeout: 90
    - require:
      - salt: {{ mname }} redefine interfaces

# create a snapshot before configuring anything
{{ mname }} create pre-config snapshot:
  salt.function:
    - name: virt.snapshot
    - tgt: {{ pillar.salt_server }}
    - kwarg: {'domain': {{ mname }}, 'name': 'pre-config', 'connection': '{{ pillar.virt.connection.url }}' }

### configures the minion
{{ mname }} call config:
  salt.runner:
    - name: state.orchestrate
    - mods: init.config
    - pillar: {'minion': {{ mname }}, 'map': {{ map }}}
    - onlyif:
      - fun: match.pillar
        tgt: 'do_config:true'

{% else %}
'-- {{ mname }} is already present.': test.nop
{% endif %}
{% endfor %}
