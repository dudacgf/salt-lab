###
## Creates a list of vms, initializes them and runs its first highstate 
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
{% set map = pillar['map'] | default('lab_minions') %}
{% import_yaml 'maps/' + map + '.yaml' as minions %}
# get list of existing vms in vm host pillar['virtual_host'] 
{#% set vhost_vmlist = salt['cmd.run']("salt " + pillar['virtual_host'] + " virt.list_domains") | 
                      default(pillar['virtual_host']) | load_yaml %#}

#
### loop through list of minions creating and configuring each one
{% do minions.pop('default', None) %}
{% for mname in minions | default([]) %}
{% set minion = minions[mname] %}

### if vm does not exists yet, create and configure it
{% if mname not in salt.virt.list_domains() %}

{{ mname }} create_instance:
  salt.runner:
    - name: cloud.profile
    - provider: {{ minion.virtual_provider }}
    - prof: {{ minion.profile | default('debian_gold') }}
    - instances:
      - {{ mname }}
    - opts:
      - clone_stratety: full
    - quiet: true


### redefines interfaces, if needed
{{ mname }} redefine interfaces:
  salt.state:
    - sls: init.redefine_interfaces
    - tgt: {{ minion.virtual_host | default(grains['id']) }}
    - pillar: {'minion': {{ mname }}, 'redefine_interfaces': {{ minion.redefine_interfaces | default(False) }}, 'minion_interfaces': {{ minion.interfaces | default({}) }} }

# wait (add minion interfaces restarts salt-minion service)
{{ mname }} wait interfaces:
  salt.wait_for_event:
    - name: salt/minion/*/start
    - id_list: [ "{{ mname }}" ]
    - timeout: 60
    - require:
      - salt: {{ mname }} redefine interfaces

### attach usb devices
{{ mname }} attach usb devices:
  salt.state:
    - sls: init.attach_usb
    - tgt: {{ minion.virtual_host | default(grains['id']) }}
    - pillar: {'minion': {{ mname }}, 'usb_devices': {{ minion.usb_devices | default(None) }}}

### configures the minion
{{ mname }} call config:
  salt.runner:
    - name: state.orchestrate
    - mods: init.config
    - pillar: {'minion': {{ mname }}, 'map': {{ map }}}
    - onlyif:
      - fun: match.pillar
        tgt: 'do_config:true'

{% endif %}
{% endfor %}
